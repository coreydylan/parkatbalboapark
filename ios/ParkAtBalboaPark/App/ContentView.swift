import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var state
    @State private var showProfile = false
    @State private var sheetDetent: PresentationDetent = .fraction(0.15)

    var body: some View {
        @Bindable var appState = state

        ParkMapView()
            .ignoresSafeArea()
            .sheet(isPresented: .constant(true)) {
                MainSheetContent(
                    showProfile: $showProfile,
                    sheetDetent: $sheetDetent
                )
                .presentationDetents(
                    [.fraction(0.15), .fraction(0.4), .large],
                    selection: $sheetDetent
                )
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.4)))
                .presentationCornerRadius(20)
                .interactiveDismissDisabled()
            }
            .fullScreenCover(isPresented: $appState.showOnboarding) {
                OnboardingView()
            }
            .onChange(of: state.parking.selectedDestination) {
                if let dest = state.parking.selectedDestination {
                    state.map.focusOn(dest.coordinate)
                }
                Task { await state.fetchRecommendations() }
            }
            .onChange(of: state.parking.visitHours) {
                Task { await state.fetchRecommendations() }
            }
            .onChange(of: state.profile.effectiveUserType) {
                Task { await state.fetchRecommendations() }
            }
            .onChange(of: state.profile.hasPass) {
                Task { await state.fetchRecommendations() }
            }
            .onChange(of: state.parking.selectedLot) {
                if state.parking.selectedLot != nil {
                    sheetDetent = .fraction(0.4)
                }
            }
            .task {
                state.locationService.requestPermission()
            }
    }
}
