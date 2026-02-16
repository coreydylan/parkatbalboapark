import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var state
    @State private var showProfile = false
    @State private var sheetDetent: PresentationDetent = .fraction(0.08)
    @State private var recommendationTask: Task<Void, Never>?
    @State private var showResidencyCard = false
    @State private var activePrompt: ContextualPromptEngine.Prompt?

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
        ParkMapView()
            .overlay(alignment: .bottom) {
                if showResidencyCard {
                    ResidencyCardView(isPresented: $showResidencyCard)
                        .padding(.bottom, 80)
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if let prompt = activePrompt, sheetDetent == .fraction(0.08) {
                    ContextualPromptView(
                        prompt: prompt,
                        onAction: {
                            if let urlString = prompt.actionURL,
                               let url = URL(string: urlString) {
                                UIApplication.shared.open(url)
                            }
                            withAnimation(.smooth(duration: 0.2)) {
                                activePrompt = nil
                            }
                        },
                        onDismiss: {
                            withAnimation(.smooth(duration: 0.2)) {
                                activePrompt = nil
                            }
                        },
                        onSnooze: prompt.snoozable ? {
                            state.profile.snoozePermitReminder()
                            withAnimation(.smooth(duration: 0.2)) {
                                activePrompt = nil
                            }
                        } : nil
                    )
                    .padding(.bottom, 80)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .sheet(isPresented: .constant(true)) {
                MainSheetContent(
                    showProfile: $showProfile,
                    sheetDetent: $sheetDetent
                )
                .presentationDetents(
                    [.fraction(0.08), .fraction(0.4), .fraction(0.65), .large],
                    selection: $sheetDetent
                )
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.4)))
                .presentationBackground(.clear)
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled()
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
            .onChange(of: sheetDetent) {
                // Hide residency card when sheet expands past collapsed
                if sheetDetent != .fraction(0.08) && showResidencyCard {
                    withAnimation(.smooth(duration: 0.2)) {
                        showResidencyCard = false
                    }
                }
            }
            .task {
                state.locationService.requestPermission()
                // Show residency card on first launch (after a brief delay for the map to load)
                if !state.profile.residencyCardDismissed {
                    try? await Task.sleep(for: .milliseconds(800))
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) {
                        showResidencyCard = true
                    }
                } else {
                    // Evaluate contextual prompts for returning users
                    try? await Task.sleep(for: .milliseconds(1200))
                    if let prompt = ContextualPromptEngine.evaluate(profile: state.profile) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) {
                            activePrompt = prompt
                        }
                    }
                }
            }
    }
}
