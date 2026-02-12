import Foundation

@MainActor @Observable
class AppState {
    let profile = UserProfile()
    let parking = ParkingStore()
    let map = MapState()
    let locationService = LocationService()

    var showOnboarding: Bool = false
    var expandedPreviewSlug: String? = nil
    var selectedDetailLot: ParkingRecommendation? = nil

    init() {
        showOnboarding = !profile.onboardingComplete
    }

    func completeOnboarding() {
        profile.completeOnboarding()
        showOnboarding = false
        Task { await loadData() }
    }

    func loadData() async {
        await parking.loadData()
        await fetchRecommendations()
    }

    func fetchRecommendations() async {
        await parking.fetchRecommendations(
            userType: profile.apiUserType,
            hasPass: profile.hasPass
        )
    }

    func selectOption(_ option: ParkingOption?) {
        parking.selectedOption = option
        // Keep selectedLot in sync for backwards compatibility
        if case .lot(let rec) = option {
            parking.selectedLot = rec
        } else {
            parking.selectedLot = nil
        }
        if let option {
            map.focusOn(option.coordinate)
        }
    }

    func selectLot(_ recommendation: ParkingRecommendation?) {
        if let rec = recommendation {
            selectOption(.lot(rec))
        } else {
            selectOption(nil)
        }
    }

    /// Step 1→2: Expand a card in-place to show Look Around preview + key data.
    func expandPreview(for recommendation: ParkingRecommendation) {
        // Tapping the same expanded card → collapse
        if expandedPreviewSlug == recommendation.lotSlug {
            collapsePreview()
            return
        }
        expandedPreviewSlug = recommendation.lotSlug
        selectOption(.lot(recommendation))
        map.startFlyover(
            lotCoordinate: recommendation.coordinate,
            destinationCoordinate: parking.selectedDestination?.coordinate
        )
    }

    /// Collapse the expanded preview back to compact card.
    func collapsePreview() {
        expandedPreviewSlug = nil
        map.stopFlyover()
        if let lot = parking.selectedLot {
            map.focusOn(lot.coordinate)
        }
    }

    /// Step 2→3: Open the full detail view (NavigationStack push).
    func openDetail(for recommendation: ParkingRecommendation) {
        selectOption(.lot(recommendation))
        selectedDetailLot = recommendation
        // Start flyover if not already running
        if expandedPreviewSlug != recommendation.lotSlug {
            map.startFlyover(
                lotCoordinate: recommendation.coordinate,
                destinationCoordinate: parking.selectedDestination?.coordinate
            )
        }
        Task { await parking.fetchPricingData() }
    }

    /// Close the full detail view (back from NavigationStack).
    func closeDetail() {
        selectedDetailLot = nil
        expandedPreviewSlug = nil
        map.stopFlyover()
        if let lot = parking.selectedLot {
            map.focusOn(lot.coordinate)
        }
    }
}
