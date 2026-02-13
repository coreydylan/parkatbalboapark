import MapKit
import SwiftUI

struct RecommendationSheet: View {
    @Environment(AppState.self) private var state

    var body: some View {
        ZStack {
            // Layer 1: Scrollable list of cards
            VStack(spacing: 0) {
                if let error = state.parking.fetchError {
                    errorState(error)
                } else if state.profile.effectiveUserType == nil {
                    emptyState
                } else if state.parking.isLoading {
                    loadingState
                } else if state.parking.recommendations.isEmpty {
                    noResultsState
                } else {
                    recommendationList
                }
            }

            // Layer 2: Fullscreen overlay (hero morph)
            if state.morph.fullscreenLotSlug != nil {
                FullscreenLotOverlay()
                    .transition(.identity)
            }
        }
        .coordinateSpace(.named("sheet"))
        .onPreferenceChange(CardFramePreferenceKey.self) { frames in
            if let slug = state.expandedPreviewSlug, let frame = frames[slug] {
                state.morph.expandedCardFrame = frame
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

    private func errorState(_ error: ParkingStore.FetchError) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(error.userMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task { await state.parking.retryLastFetch() }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    // MARK: - List

    private var recommendationList: some View {
        let options = state.parking.displayedOptions

        return Group {
            if options.isEmpty && (state.parking.showFreeOnly || !state.parking.showMeters) {
                emptyFilterState
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            filterBar

                            LazyVStack(spacing: 10) {
                                ForEach(Array(options.enumerated()), id: \.element.id) {
                                    index, option in
                                    optionRow(option: option, index: index)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                            .padding(.bottom, 100)
                        }
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

    private var emptyFilterState: some View {
        VStack(spacing: 12) {
            Image(systemName: "car.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(emptyFilterMessage)
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
    }

    private var emptyFilterMessage: String {
        if state.parking.showFreeOnly {
            switch state.profile.effectiveUserType {
            case .nonresident:
                return "No free parking available for visitors. Verified San Diego residents can park free at most lots."
            case .resident:
                return "No free lots match your destination. Try a different location."
            case .ada:
                return "No parking options match your current filters."
            default:
                return "No free parking available with your current filters."
            }
        }
        return "No parking options match\nyour current filters"
    }

    @ViewBuilder
    private func optionRow(option: ParkingOption, index: Int) -> some View {
        switch option {
        case .lot(let rec):
            LotCardRow(
                recommendation: rec,
                rank: index + 1,
                option: option,
                elevationProfile: state.parking.elevationProfiles[rec.lotSlug]
            )
        case .meter(let seg, let cost):
            StreetMeterCard(
                segment: seg,
                cost: cost,
                isSelected: state.parking.selectedOption == option,
                walkingTimeDisplay: state.parking.meterWalkingDisplays[seg.segmentId],
                walkingDistanceMeters: state.parking.meterWalkingDistances[seg.segmentId],
                elevationProfile: state.parking.elevationProfiles["meter-\(seg.segmentId)"]
            )
            .id(option.id)
            .onTapGesture {
                state.selectOption(option)
            }
        }
    }
}

// MARK: - Lot Card Row — Single morphing view

/// A unified card that smoothly morphs between compact and expanded states.
/// Uses `matchedGeometryEffect` on shared elements (name, cost) so they
/// glide between positions instead of popping. The expanded state shows
/// full-bleed Look Around imagery with content overlaid on a gradient.
private struct LotCardRow: View {
    @Environment(AppState.self) private var state
    @Namespace private var cardNS
    let recommendation: ParkingRecommendation
    let rank: Int
    let option: ParkingOption
    var elevationProfile: WalkingDirectionsService.ElevationProfile? = nil

    private var isExpanded: Bool {
        state.expandedPreviewSlug == recommendation.lotSlug
    }

    private var isOverlayActive: Bool {
        state.morph.fullscreenLotSlug == recommendation.lotSlug
    }

    private var scene: MKLookAroundScene? {
        state.morph.sceneCache[recommendation.lotSlug]
    }

    private var lot: ParkingLot? {
        state.parking.lotLookup[recommendation.lotSlug]
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Layer 1: Background
            backgroundLayer

            // Layer 2: Content overlay
            contentLayer
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    isExpanded
                        ? Color.accentColor.opacity(0.3)
                        : (state.parking.selectedOption == option
                            ? Color.accentColor.opacity(0.5) : .clear),
                    lineWidth: isExpanded ? 1.5 : 2
                )
        )
        .shadow(
            color: .black.opacity(isExpanded ? 0.18 : 0.06),
            radius: isExpanded ? 16 : 4,
            y: isExpanded ? 8 : 2
        )
        .id(option.id)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture { handleTap() }
        // Report expanded card frame to sheet coordinate space
        .background {
            if isExpanded {
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: CardFramePreferenceKey.self,
                            value: [recommendation.lotSlug: geo.frame(in: .named("sheet"))]
                        )
                }
            }
        }
        // Hide card when overlay is active
        .opacity(isOverlayActive ? 0 : 1)
        // Horizontal swipe gesture when expanded
        .simultaneousGesture(isExpanded ? expandedSwipeGesture : nil)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.6), trigger: isExpanded)
        .task(id: isExpanded) {
            if isExpanded && scene == nil {
                let fetchedScene = await LookAroundService.fetchScene(
                    lat: recommendation.lat, lng: recommendation.lng
                )
                if let fetchedScene {
                    state.morph.sceneCache[recommendation.lotSlug] = fetchedScene
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(isExpanded ? "Double tap for full details" : "Double tap to preview")
    }

    // MARK: - Expanded Swipe Gesture

    private var expandedSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                // Only trigger if horizontal movement dominates
                guard abs(horizontal) > abs(vertical) * 1.5 else { return }
                guard abs(horizontal) > 80 || abs(value.velocity.width) > 500 else { return }

                let direction: SwipeDirection = horizontal < 0 ? .left : .right
                state.expandedSwipe(direction: direction)
            }
    }

    // MARK: - Background Layer

    @ViewBuilder
    private var backgroundLayer: some View {
        if isExpanded {
            // Full-bleed Look Around or tier gradient
            ZStack {
                if let scene {
                    LookAroundPreview(initialScene: scene)
                        .allowsHitTesting(false)
                        .transition(.opacity.animation(.easeIn(duration: 0.4)))
                } else {
                    expandedFallback
                }

                // Gradient for text readability
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .black.opacity(0.25), location: 0.35),
                        .init(color: .black.opacity(0.85), location: 1.0),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                // Invisible tap catcher — LookAroundPreview is a UIKit view
                // whose gesture recognizers ignore .allowsHitTesting(false).
                // This overlay sits on top and forwards taps to .onTapGesture.
                Color.white.opacity(0.001)
            }
            .frame(height: 300)
            .transition(.opacity)
        } else {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    // MARK: - Content Layer

    @ViewBuilder
    private var contentLayer: some View {
        if isExpanded {
            expandedContent
                .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            compactContent
                .transition(.opacity)
        }
    }

    // MARK: - Compact Content

    private var compactContent: some View {
        HStack(spacing: 12) {
            rankBadge

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(recommendation.lotDisplayName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .matchedGeometryEffect(id: "name", in: cardNS)
                    Spacer()
                    Text(recommendation.costDisplay)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(recommendation.costColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(recommendation.costColor.opacity(0.12))
                        )
                        .matchedGeometryEffect(id: "cost", in: cardNS)
                }

                HStack(spacing: 12) {
                    if let walkTime = recommendation.walkingTimeDisplay {
                        Label(walkTime, systemImage: "figure.walk")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let elevation = elevationProfile,
                        elevation.isNotable(
                            distanceMeters: recommendation.walkingDistanceMeters)
                    {
                        Label(
                            "\(Int(elevation.gainMeters * 3.281))ft\u{2191}",
                            systemImage: "arrow.up.right"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            elevation.isSteep(
                                distanceMeters: recommendation.walkingDistanceMeters)
                                ? .orange : .secondary)
                    }

                    if recommendation.hasTram {
                        Label("Tram", systemImage: "tram.fill")
                            .font(.caption)
                            .foregroundStyle(Color.tram)
                    }

                    Spacer()
                }

                if let tip = recommendation.tips.first {
                    Text(tip)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Spacer(minLength: 0)

            // Tier badge
            Text(recommendation.tier.name)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(recommendation.tier.color.opacity(0.9), in: Capsule())

            // Name + cost
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.lotDisplayName)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .matchedGeometryEffect(id: "name", in: cardNS)

                    if let lot {
                        Text(lot.address)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }

                Spacer()

                Text(recommendation.costDisplay)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(recommendation.isFree ? .green : .white)
                    .matchedGeometryEffect(id: "cost", in: cardNS)
            }

            // Stats + details affordance
            HStack(spacing: 14) {
                if state.profile.activeCapacity == .ada {
                    Label("ADA", systemImage: "figure.roll")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)
                }

                if let walkTime = recommendation.walkingTimeDisplay {
                    Label(walkTime, systemImage: "figure.walk")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))
                }

                if recommendation.hasTram {
                    Label("Tram", systemImage: "tram.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))
                }

                if let lot, let capacity = lot.capacity {
                    Label("\(capacity) spots", systemImage: "car.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("Details")
                        .font(.caption.weight(.semibold))
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .padding(.top, 16)
        .frame(height: 300, alignment: .bottom)
    }

    // MARK: - Components

    private var rankBadge: some View {
        Text("#\(rank)")
            .font(.caption.weight(.bold))
            .foregroundStyle(rank <= 3 ? .white : .secondary)
            .frame(width: 32, height: 32)
            .background(
                Circle()
                    .fill(rank <= 3 ? Color.accentColor : Color(.systemGray5))
            )
    }

    private var expandedFallback: some View {
        LinearGradient(
            colors: [
                recommendation.tier.color.opacity(0.5),
                recommendation.tier.color.opacity(0.15),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Image(systemName: "car.fill")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.12))
        }
    }

    // MARK: - Tap

    private func handleTap() {
        if isExpanded {
            state.openDetail(for: recommendation)
        } else {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) {
                state.expandPreview(for: recommendation)
            }
        }
    }
}
