import Foundation

@MainActor @Observable
class AppState {
    let profile = UserProfile()
    let parking = ParkingStore()
    let map = MapState()
    let locationService = LocationService()

    var showOnboarding: Bool = false

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
}
