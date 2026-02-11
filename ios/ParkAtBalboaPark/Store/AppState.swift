import Foundation
import MapKit
import SwiftUI

@MainActor @Observable
class AppState {
    // MARK: - User Profile (persisted via UserDefaults)

    var userRoles: Set<UserType> = [] {
        didSet { persistUserRoles() }
    }

    var activeCapacity: UserType? {
        didSet {
            UserDefaults.standard.set(activeCapacity?.rawValue, forKey: "activeCapacity")
            Task { await fetchRecommendations() }
        }
    }

    var hasPass: Bool = false {
        didSet {
            UserDefaults.standard.set(hasPass, forKey: "hasPass")
            Task { await fetchRecommendations() }
        }
    }

    var onboardingComplete: Bool = false {
        didSet { UserDefaults.standard.set(onboardingComplete, forKey: "onboardingComplete") }
    }

    // MARK: - Selections

    var selectedDestination: Destination? = nil {
        didSet {
            selectedLot = nil
            Task { await fetchRecommendations() }
        }
    }

    var visitHours: Int = 2 {
        didSet { Task { await fetchRecommendations() } }
    }

    var selectedLot: ParkingRecommendation? = nil

    // MARK: - Data

    var lots: [ParkingLot] = []
    var destinations: [Destination] = []
    var recommendations: [ParkingRecommendation] = []
    var enforcementActive: Bool = false
    var tramData: TramData? = nil

    // MARK: - Map State

    var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 32.7341, longitude: -117.1446),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    ))
    var mapFilters: MapFilters = MapFilters()

    // MARK: - UI State

    enum PanelMode { case recommendations, search, profile }

    var isLoading: Bool = false
    var sheetDetent: PanelDetent = .peek
    var panelMode: PanelMode = .recommendations
    var searchText: String = ""
    var showOnboarding: Bool = false
    var showFreeOnly: Bool = false

    // MARK: - Services

    private let api = APIClient.shared
    let locationService = LocationService()

    // MARK: - Task Cancellation

    private var recommendationTask: Task<Void, Never>?

    // MARK: - Computed

    /// The effective user type for pricing (activeCapacity or first role).
    var effectiveUserType: UserType? {
        activeCapacity ?? userRoles.first
    }

    /// Destinations filtered by search text, grouped by area.
    var filteredDestinations: [DestinationArea: [Destination]] {
        let filtered = searchText.isEmpty
            ? destinations
            : destinations.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
                    || $0.displayName.localizedCaseInsensitiveContains(searchText)
            }
        return Dictionary(grouping: filtered, by: \.area)
    }

    /// Recommendations sorted by closest and filtered by free-only toggle.
    var displayedRecommendations: [ParkingRecommendation] {
        var recs = recommendations

        if showFreeOnly {
            recs = recs.filter { $0.isFree }
        }

        // Sort by closest when a destination is selected
        if selectedDestination != nil {
            recs.sort { ($0.walkingDistanceMeters ?? .infinity) < ($1.walkingDistanceMeters ?? .infinity) }
        }

        return recs
    }

    /// Sorted area keys for display.
    var sortedAreas: [DestinationArea] {
        let order: [DestinationArea] = [
            .centralMesa, .palisades, .eastMesa, .floridaCanyon, .morleyField, .panAmerican,
        ]
        return order.filter { filteredDestinations[$0] != nil }
    }

    // MARK: - Init

    init() {
        loadPersistedState()
        loadBundledData()
    }

    private func loadPersistedState() {
        onboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")
        hasPass = UserDefaults.standard.bool(forKey: "hasPass")
        showOnboarding = !onboardingComplete

        if let rolesData = UserDefaults.standard.data(forKey: "userRoles"),
            let roles = try? JSONDecoder().decode(Set<UserType>.self, from: rolesData)
        {
            userRoles = roles
        }
        if let capacityRaw = UserDefaults.standard.string(forKey: "activeCapacity"),
            let capacity = UserType(rawValue: capacityRaw)
        {
            activeCapacity = capacity
        }
    }

    private func persistUserRoles() {
        if let data = try? JSONEncoder().encode(userRoles) {
            UserDefaults.standard.set(data, forKey: "userRoles")
        }
    }

    private func loadBundledData() {
        lots = BundledDataService.loadLots()
        destinations = BundledDataService.loadDestinations()
        tramData = BundledDataService.loadTramData()
    }

    // MARK: - Actions

    func toggleRole(_ type: UserType) {
        if userRoles.contains(type) {
            userRoles.remove(type)
            if activeCapacity == type {
                activeCapacity = userRoles.first
            }
        } else {
            userRoles.insert(type)
            if activeCapacity == nil {
                activeCapacity = type
            }
        }
        Task { await fetchRecommendations() }
    }

    func selectLot(_ recommendation: ParkingRecommendation?) {
        selectedLot = recommendation
        if let rec = recommendation {
            withAnimation(.smooth) {
                cameraPosition = .camera(MapCamera(
                    centerCoordinate: rec.coordinate,
                    distance: 800
                ))
            }
            sheetDetent = .half
        }
    }

    func completeOnboarding() {
        onboardingComplete = true
        showOnboarding = false
        Task { await loadData() }
    }

    // MARK: - Data Loading

    func loadData() async {
        async let lotsResult = api.fetchLots()
        async let destinationsResult = api.fetchDestinations()
        async let enforcementResult = api.fetchEnforcement()

        do {
            let (fetchedLots, fetchedDestinations, enforcement) = try await (
                lotsResult, destinationsResult, enforcementResult
            )
            await MainActor.run {
                self.lots = fetchedLots
                self.destinations = fetchedDestinations
                self.enforcementActive = enforcement.active
            }
        } catch {
            print("Failed to load data: \(error)")
            // Bundled data is already loaded as fallback
        }

        await fetchRecommendations()
    }

    func fetchRecommendations() async {
        // Cancel any in-flight recommendation fetch
        recommendationTask?.cancel()

        let task = Task { @MainActor [weak self] in
            guard let self else { return }

            guard let userType = self.effectiveUserType else {
                self.recommendations = []
                return
            }

            self.isLoading = true

            do {
                try Task.checkCancellation()

                let destinationSlug = self.selectedDestination?.slug
                let hasPass = self.hasPass
                let visitHours = self.visitHours

                let response = try await self.api.fetchRecommendations(
                    userType: userType,
                    hasPass: hasPass,
                    destinationSlug: destinationSlug,
                    visitHours: visitHours
                )

                try Task.checkCancellation()

                self.recommendations = response.recommendations
                self.enforcementActive = response.enforcementActive
                self.isLoading = false
            } catch is CancellationError {
                // Task was cancelled; do not update state
            } catch {
                print("Failed to fetch recommendations: \(error)")
                self.isLoading = false
                // TODO: Fall back to local pricing engine
            }
        }

        recommendationTask = task
        await task.value
    }
}

// MARK: - Map Filters

struct MapFilters {
    var showTram: Bool = false
    var showRestrooms: Bool = false
    var showWater: Bool = false
    var showEvCharging: Bool = false
}
