import SwiftUI

struct RecommendationSheet: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader

            if state.effectiveUserType == nil {
                emptyState
            } else if state.isLoading {
                loadingState
            } else if state.recommendations.isEmpty {
                noResultsState
            } else {
                filterBar
                recommendationList
            }
        }
    }

    // MARK: - Header

    private var sheetHeader: some View {
        VStack(spacing: 4) {
            if state.effectiveUserType != nil {
                HStack(spacing: 6) {
                    Circle()
                        .fill(state.enforcementActive ? .orange : .green)
                        .frame(width: 8, height: 8)
                    Text(state.enforcementActive ? "Enforcement active" : "Free parking hours")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(state.enforcementActive ? .orange : .green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: Capsule())
            }

            if !state.displayedRecommendations.isEmpty {
                Text("\(state.displayedRecommendations.count) parking options")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 8) {
            // Sort indicator
            Label(
                state.selectedDestination != nil ? "Closest" : "Best match",
                systemImage: state.selectedDestination != nil ? "location.fill" : "star.fill"
            )
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.quaternary.opacity(0.6), in: Capsule())

            // Free only filter
            Button {
                withAnimation(.snappy(duration: 0.2)) {
                    state.showFreeOnly.toggle()
                }
            } label: {
                Label("Free only", systemImage: state.showFreeOnly ? "checkmark.circle.fill" : "circle")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(state.showFreeOnly ? .white : .secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        state.showFreeOnly ? AnyShapeStyle(.green) : AnyShapeStyle(.quaternary.opacity(0.6)),
                        in: Capsule()
                    )
            }
            .sensoryFeedback(.selection, trigger: state.showFreeOnly)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    // MARK: - States

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "car.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Set up your profile to see\nparking recommendations")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 16)
                    .fill(.quaternary)
                    .frame(height: 90)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No parking options found")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - List

    private var recommendationList: some View {
        let recs = state.displayedRecommendations

        return Group {
            if recs.isEmpty && state.showFreeOnly {
                VStack(spacing: 12) {
                    Image(systemName: "car.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No free parking available\nat this time")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Show all") {
                        state.showFreeOnly = false
                    }
                    .font(.subheadline.weight(.medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(recs.enumerated()), id: \.element.id) { index, rec in
                            RecommendationCard(
                                recommendation: rec,
                                rank: index + 1,
                                isSelected: state.selectedLot?.lotSlug == rec.lotSlug
                            )
                            .onTapGesture {
                                state.selectLot(rec)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}
