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
                    [.fraction(0.08), .fraction(0.4), .fraction(0.5), .fraction(0.55), .large],
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
                if state.parking.selectedOption != nil {
                    sheetDetent = .fraction(0.4)
                }
            }
            .onChange(of: state.expandedPreviewSlug) {
                if state.expandedPreviewSlug != nil && state.morph.fullscreenLotSlug == nil {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        sheetDetent = .fraction(0.55)
                    }
                } else if state.expandedPreviewSlug == nil && state.morph.fullscreenLotSlug == nil {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        sheetDetent = .fraction(0.4)
                    }
                }
            }
            .onChange(of: state.morph.fullscreenLotSlug) {
                if state.morph.fullscreenLotSlug != nil {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                        sheetDetent = .large
                    }
                } else {
                    // Back to list state
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        sheetDetent = .fraction(0.4)
                    }
                }
            }
            .task {
                state.locationService.requestPermission()
            }
    }
}
