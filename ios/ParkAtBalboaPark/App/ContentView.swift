import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var state
    @State private var showProfile = false
    @State private var sheetDetent: PresentationDetent = .fraction(0.08)
    @State private var recommendationTask: Task<Void, Never>?

    private var recommendationSignature: Int {
        var hasher = Hasher()
        hasher.combine(state.parking.startTime)
        hasher.combine(state.parking.endTime)
        hasher.combine(state.profile.effectiveUserType)
        hasher.combine(state.profile.hasPass)
        hasher.combine(state.profile.isVerifiedResident)
        return hasher.finalize()
    }

    var body: some View {
        @Bindable var appState = state

        ParkMapView()
            .sheet(isPresented: .constant(true)) {
                MainSheetContent(
                    showProfile: $showProfile,
                    sheetDetent: $sheetDetent
                )
                .presentationDetents(
                    [.fraction(0.08), .fraction(0.4), .large],
                    selection: $sheetDetent
                )
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.4)))
                .presentationBackground(.clear)
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled()
            }
            .fullScreenCover(isPresented: $appState.showOnboarding) {
                OnboardingView()
            }
            .onChange(of: state.parking.selectedDestination) {
                // Pan map to destination immediately
                if let dest = state.parking.selectedDestination {
                    state.map.focusOn(dest.coordinate)
                }
            }
            .onChange(of: recommendationSignature) {
                guard state.parking.selectedDestination != nil else { return }
                guard !state.parking.recommendations.isEmpty else { return }
                recommendationTask?.cancel()
                recommendationTask = Task {
                    try? await Task.sleep(for: .milliseconds(100))
                    guard !Task.isCancelled else { return }
                    await state.fetchRecommendations()
                }
            }
            .onChange(of: state.parking.selectedOption) {
                // Only expand from collapsed pill — never shrink the sheet
                if state.parking.selectedOption != nil
                    && sheetDetent == .fraction(0.08)
                {
                    sheetDetent = .fraction(0.4)
                }
            }
            .onChange(of: state.detailRecommendation) {
                // Expand sheet when lot detail opens
                if state.detailRecommendation != nil && sheetDetent != .large {
                    withAnimation(.smooth(duration: 0.3)) {
                        sheetDetent = .large
                    }
                }
                // Return to recommendations list when lot detail closes
                if state.detailRecommendation == nil && sheetDetent == .large {
                    withAnimation(.smooth(duration: 0.3)) {
                        sheetDetent = .fraction(0.4)
                    }
                }
            }
            .task {
                state.locationService.requestPermission()
            }
    }
}
