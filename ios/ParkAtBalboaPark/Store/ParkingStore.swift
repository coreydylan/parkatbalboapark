import CoreLocation
import Foundation
import SwiftUI

@MainActor @Observable
class ParkingStore {
    // MARK: - Data

    var lots: [ParkingLot] = []
    var destinations: [Destination] = []
    var recommendations: [ParkingRecommendation] = []
    var enforcementActive: Bool = false
    var tramData: TramData? = nil
    var streetSegments: [StreetSegment] = []

    // MARK: - Selections

    var selectedDestination: Destination? = nil
    var selectedLot: ParkingRecommendation? = nil
    var visitHours: Int = 2
    var showFreeOnly: Bool = false

    // MARK: - UI State

    var isLoading: Bool = false

    /// Walking route polylines keyed by lot slug, populated by MapKit directions.
    var walkingRoutes: [String: [CLLocationCoordinate2D]] = [:]

    /// Elevation profiles keyed by lot slug, populated from Open-Meteo API.
    var elevationProfiles: [String: WalkingDirectionsService.ElevationProfile] = [:]

    // MARK: - Services

    private let api = APIClient.shared
    private var recommendationTask: Task<Void, Never>?

    // MARK: - Computed

    var displayedRecommendations: [ParkingRecommendation] {
        var recs = recommendations
        if showFreeOnly {
            recs = recs.filter { $0.isFree }
        }
        if selectedDestination != nil {
            recs.sort {
                ($0.walkingDistanceMeters ?? .infinity) < ($1.walkingDistanceMeters ?? .infinity)
            }
        }
        return recs
    }

    var lotAnnotations: [LotAnnotation] {
        if recommendations.isEmpty {
            return lots.map { lot in
                LotAnnotation(
                    lotSlug: lot.slug,
                    displayName: lot.displayName,
                    coordinate: lot.coordinate,
                    tier: nil,
                    costColor: .gray,
                    hasTram: lot.hasTramStop
                )
            }
        } else {
            return recommendations.map { rec in
                LotAnnotation(
                    lotSlug: rec.lotSlug,
                    displayName: rec.lotDisplayName,
                    coordinate: rec.coordinate,
                    tier: rec.tier,
                    costColor: rec.costColor,
                    hasTram: rec.hasTram
                )
            }
        }
    }

    // MARK: - Init

    init() {
        loadBundledData()
    }

    private func loadBundledData() {
        lots = BundledDataService.loadLots()
        destinations = BundledDataService.loadDestinations()
        tramData = BundledDataService.loadTramData()
    }

    // MARK: - Actions

    func selectDestination(_ dest: Destination?) {
        selectedDestination = dest
        selectedLot = nil
        walkingRoutes = [:]
        elevationProfiles = [:]
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
            self.lots = fetchedLots
            self.destinations = fetchedDestinations
            self.enforcementActive = enforcement.active
        } catch {
            print("Failed to load data: \(error)")
        }
    }

    func fetchStreetSegments() async {
        guard streetSegments.isEmpty else { return }
        do {
            streetSegments = try await api.fetchStreetSegments()
        } catch {
            print("Failed to fetch street segments: \(error)")
        }
    }

    func fetchRecommendations(userType: UserType?, hasPass: Bool) async {
        recommendationTask?.cancel()

        let task = Task { @MainActor [weak self] in
            guard let self else { return }

            guard let userType else {
                self.recommendations = []
                return
            }

            self.isLoading = true

            do {
                try Task.checkCancellation()

                let response = try await self.api.fetchRecommendations(
                    userType: userType,
                    hasPass: hasPass,
                    destinationSlug: self.selectedDestination?.slug,
                    visitHours: self.visitHours
                )

                try Task.checkCancellation()

                self.recommendations = response.recommendations
                self.enforcementActive = response.enforcementActive
                self.isLoading = false

                // Enrich with real MapKit walking times and routes
                if let dest = self.selectedDestination {
                    self.walkingRoutes = [:]
                    Task {
                        let walkTimes = await WalkingDirectionsService.fetchWalkingTimes(
                            for: self.recommendations,
                            to: dest.coordinate
                        )
                        var routes: [String: [CLLocationCoordinate2D]] = [:]
                        for i in self.recommendations.indices {
                            let slug = self.recommendations[i].lotSlug
                            if let result = walkTimes[slug] {
                                self.recommendations[i].walkingDistanceMeters = result.distanceMeters
                                self.recommendations[i].walkingTimeSeconds = result.timeSeconds
                                self.recommendations[i].walkingTimeDisplay =
                                    WalkingDirectionsService.formatWalkTime(seconds: result.timeSeconds)
                                routes[slug] = result.routeCoordinates
                            }
                        }
                        self.walkingRoutes = routes

                        // Fetch elevation profiles for all routes
                        let profiles = await WalkingDirectionsService.fetchElevationProfiles(
                            for: routes
                        )
                        self.elevationProfiles = profiles
                    }
                } else {
                    self.walkingRoutes = [:]
                    self.elevationProfiles = [:]
                }
            } catch is CancellationError {
                // Task was cancelled; do not update state
            } catch {
                print("Failed to fetch recommendations: \(error)")
                self.isLoading = false
            }
        }

        recommendationTask = task
        await task.value
    }
}
