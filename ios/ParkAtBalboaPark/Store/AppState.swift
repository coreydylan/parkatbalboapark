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

    func selectLot(_ recommendation: ParkingRecommendation?) {
        parking.selectedLot = recommendation
        if let rec = recommendation {
            map.focusOn(rec.coordinate)
        }
    }
}
