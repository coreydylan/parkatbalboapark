import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var state
    @State private var showProfile = false
    @State private var sheetDetent: PresentationDetent = .fraction(0.08)

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
            .onChange(of: state.parking.startTime) {
                if !state.parking.recommendations.isEmpty {
                    Task { await state.fetchRecommendations() }
                }
            }
            .onChange(of: state.parking.endTime) {
                if !state.parking.recommendations.isEmpty {
                    Task { await state.fetchRecommendations() }
                }
            }
            .onChange(of: state.profile.effectiveUserType) {
                if state.parking.selectedDestination != nil && !state.parking.recommendations.isEmpty {
                    Task { await state.fetchRecommendations() }
                }
            }
            .onChange(of: state.profile.hasPass) {
                if !state.parking.recommendations.isEmpty {
                    Task { await state.fetchRecommendations() }
                }
            }
            .onChange(of: state.profile.isVerifiedResident) {
                if !state.parking.recommendations.isEmpty {
                    Task { await state.fetchRecommendations() }
                }
            }
            .onChange(of: state.parking.selectedOption) {
                if state.parking.selectedOption != nil {
                    sheetDetent = .fraction(0.4)
                }
            }
            .onChange(of: state.expandedPreviewSlug) {
                if state.expandedPreviewSlug != nil && state.selectedDetailLot == nil {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        sheetDetent = .fraction(0.55)
                    }
                } else if state.expandedPreviewSlug == nil && state.selectedDetailLot == nil {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        sheetDetent = .fraction(0.4)
                    }
                }
            }
            .onChange(of: state.selectedDetailLot) {
                if state.selectedDetailLot != nil {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                        sheetDetent = .large
                    }
                } else {
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
