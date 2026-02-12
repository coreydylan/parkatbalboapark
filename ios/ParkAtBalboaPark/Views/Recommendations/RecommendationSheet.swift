import SwiftUI

struct RecommendationSheet: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(spacing: 0) {
            if state.profile.effectiveUserType == nil {
                emptyState
            } else if state.parking.isLoading {
                loadingState
            } else if state.parking.recommendations.isEmpty {
                noResultsState
            } else {
                VisitTimePicker()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                filterBar
                recommendationList
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 8) {
            Label(
                state.parking.selectedDestination != nil ? "Closest" : "Best match",
                systemImage: state.parking.selectedDestination != nil
                    ? "location.fill" : "star.fill"
            )
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.quaternary.opacity(0.6), in: Capsule())

            Button {
                withAnimation(.snappy(duration: 0.2)) {
                    state.parking.showFreeOnly.toggle()
                }
            } label: {
                Label(
                    "Free only",
                    systemImage: state.parking.showFreeOnly
                        ? "checkmark.circle.fill" : "circle"
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(state.parking.showFreeOnly ? .white : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    state.parking.showFreeOnly
                        ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(
                            .quaternary.opacity(0.6)),
                    in: Capsule()
                )
            }
            .sensoryFeedback(.selection, trigger: state.parking.showFreeOnly)
            .accessibilityAddTraits(.isToggle)
            .accessibilityValue(state.parking.showFreeOnly ? "On" : "Off")

            Button {
                withAnimation(.snappy(duration: 0.2)) {
                    state.parking.showMeters.toggle()
                }
            } label: {
                Label(
                    "Meters",
                    systemImage: state.parking.showMeters
                        ? "checkmark.circle.fill" : "circle"
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(state.parking.showMeters ? .white : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    state.parking.showMeters
                        ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(
                            .quaternary.opacity(0.6)),
                    in: Capsule()
                )
            }
            .sensoryFeedback(.selection, trigger: state.parking.showMeters)
            .accessibilityAddTraits(.isToggle)
            .accessibilityValue(state.parking.showMeters ? "On" : "Off")

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
        let options = state.parking.displayedOptions

        return Group {
            if options.isEmpty && (state.parking.showFreeOnly || !state.parking.showMeters) {
                VStack(spacing: 12) {
                    Image(systemName: "car.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No parking options match\nyour current filters")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Reset filters") {
                        state.parking.showFreeOnly = false
                        state.parking.showMeters = true
                    }
                    .font(.subheadline.weight(.medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(Array(options.enumerated()), id: \.element.id) {
                                index, option in
                                switch option {
                                case .lot(let rec):
                                    RecommendationCard(
                                        recommendation: rec,
                                        rank: index + 1,
                                        isSelected: state.parking.selectedOption == option,
                                        elevationProfile: state.parking.elevationProfiles[
                                            rec.lotSlug]
                                    )
                                    .id(option.id)
                                    .onTapGesture {
                                        state.selectOption(option)
                                    }
                                case .meter(let seg, let cost):
                                    StreetMeterCard(
                                        segment: seg,
                                        cost: cost,
                                        isSelected: state.parking.selectedOption == option,
                                        walkingTimeDisplay: state.parking.meterWalkingDisplays[
                                            seg.segmentId],
                                        elevationProfile: state.parking.elevationProfiles[
                                            "meter-\(seg.segmentId)"]
                                    )
                                    .id(option.id)
                                    .onTapGesture {
                                        state.selectOption(option)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 100)
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: state.parking.selectedOption) {
                        if let selected = state.parking.selectedOption {
                            withAnimation(.snappy(duration: 0.3)) {
                                proxy.scrollTo(selected.id, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
    }
}
