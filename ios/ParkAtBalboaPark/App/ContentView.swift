import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var state = state

        ZStack {
            ParkMapView()
                .ignoresSafeArea()

            BottomPanel(detent: $state.sheetDetent) {
                PanelContentView()
            }
        }
        .fullScreenCover(isPresented: $state.showOnboarding) {
            OnboardingView()
        }
    }
}
