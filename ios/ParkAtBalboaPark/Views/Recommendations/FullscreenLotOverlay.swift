import MapKit
import SwiftUI

/// Fullscreen hero morph overlay — appears at the expanded card's position and
/// animates to fill the entire sheet. Provides Look Around background, detail
/// sections, dismiss-by-drag, and horizontal paging between lots.
struct FullscreenLotOverlay: View {
    @Environment(AppState.self) private var state

    @State private var detailAppeared = false
    @State private var rawElevations: [Double]? = nil
    @State private var dismissHapticFired = false
    @State private var scrollDismissTriggered = false
    @State private var elevationTask: Task<Void, Never>?

    private var morph: CardMorphState { state.morph }

    private var recommendation: ParkingRecommendation? {
        guard let slug = morph.fullscreenLotSlug else { return nil }
        return state.parking.recommendations.first { $0.lotSlug == slug }
    }

    private var lot: ParkingLot? {
        guard let slug = morph.fullscreenLotSlug else { return nil }
        return state.parking.lotLookup[slug]
    }

    private var scene: MKLookAroundScene? {
        guard let slug = morph.fullscreenLotSlug else { return nil }
        return morph.sceneCache[slug]
    }

    var body: some View {
        GeometryReader { geo in
            if let recommendation {
                // During drag: keep full frame, apply GPU transforms (scaleEffect + offset).
                // After gesture ends: use morphFrame for animated position interpolation.
                let frame = morph.isDragging
                    ? CGRect(origin: .zero, size: geo.size)
                    : morph.morphFrame(in: geo.size)

                ZStack {
                    // Background: Look Around or fallback gradient
                    lookAroundBackground(recommendation: recommendation)

                    // Readability gradient
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black.opacity(0.15), location: 0.25),
                            .init(color: .black.opacity(0.7), location: 0.55),
                            .init(color: .black.opacity(0.92), location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .allowsHitTesting(false)

                    // Scrollable content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Push header content down
                            Spacer()
                                .frame(height: max(geo.size.height * 0.35, 200))

                            headerContent(recommendation: recommendation)

                            if detailAppeared {
                                detailSections(recommendation: recommendation)
                            }
                        }
                        .padding(.bottom, 60)
                    }
                    .id(morph.fullscreenLotSlug)
                    .scrollIndicators(.hidden)
                    .onScrollGeometryChange(for: CGFloat.self) { geo in
                        geo.contentOffset.y
                    } action: { _, newOffset in
                        // Overscroll past top → collapse back to list
                        if newOffset < -60 && !scrollDismissTriggered {
                            scrollDismissTriggered = true
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            dismissOverlay()
                        }
                    }

                    // Top controls: drag handle + close button
                    VStack(spacing: 0) {
                        ZStack(alignment: .topTrailing) {
                            // Full-width drag zone for dismiss gesture
                            Color.clear
                                .frame(height: 56)
                                .contentShape(Rectangle())
                                .gesture(dismissGesture)

                            // Centered drag handle
                            Capsule()
                                .fill(.white.opacity(0.5))
                                .frame(width: 36, height: 5)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 14)
                                .allowsHitTesting(false)

                            // Close button
                            Button {
                                dismissOverlay()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .white.opacity(0.35))
                                    .frame(width: 44, height: 44)
                                    .contentShape(Circle())
                            }
                            .padding(.trailing, 12)
                            .padding(.top, 8)
                        }

                        Spacer()
                    }
                }
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
                .scaleEffect(morph.isDragging ? morph.dismissScale : 1.0)
                .offset(y: morph.isDragging ? morph.dismissOffsetY : 0)
                .clipShape(RoundedRectangle(cornerRadius: morph.cornerRadius, style: .continuous))
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                .simultaneousGesture(pagingGesture)
                .onAppear {
                    scrollDismissTriggered = false
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                        morph.dismissProgress = 0
                    } completion: {
                        withAnimation(.easeOut(duration: 0.35)) {
                            detailAppeared = true
                        }
                    }
                }
                .onDisappear {
                    detailAppeared = false
                    morph.isDragging = false
                    morph.dismissProgress = 0
                }
                .task {
                    elevationTask?.cancel()
                    elevationTask = Task {
                        if let coords = state.parking.walkingRoutes[recommendation.lotSlug] {
                            rawElevations = await WalkingDirectionsService.fetchRawElevations(
                                coords: coords)
                        }
                    }
                    await elevationTask?.value
                }
            }
        }
        .ignoresSafeArea()
        .onChange(of: recommendation == nil) { _, isNil in
            if isNil && morph.fullscreenLotSlug != nil {
                dismissOverlay()
            }
        }
    }

    // MARK: - Dismiss Helper

    private func dismissOverlay() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.88)) {
            morph.dismissProgress = 1
        } completion: {
            state.closeDetail()
        }
    }

    // MARK: - Look Around Background

    @ViewBuilder
    private func lookAroundBackground(recommendation: ParkingRecommendation) -> some View {
        if let scene {
            LookAroundPreview(initialScene: scene)
        } else {
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
                    .font(.system(size: 60))
                    .foregroundStyle(.white.opacity(0.08))
            }
        }
    }

    // MARK: - Header Content

    private func headerContent(recommendation: ParkingRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Tier badge
            Text(recommendation.tier.name)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(recommendation.tier.color.opacity(0.9), in: Capsule())

            // Name + cost
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(recommendation.lotDisplayName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)

                    if let lot {
                        Text(lot.address)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(recommendation.costDisplay)
                        .font(.title.weight(.bold))
                        .foregroundStyle(recommendation.isFree ? .green : .white)
                }
            }

            // Stats row
            HStack(spacing: 14) {
                if let walkTime = recommendation.walkingTimeDisplay {
                    Label(walkTime, systemImage: "figure.walk")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                }

                if recommendation.hasTram {
                    Label("Tram", systemImage: "tram.fill")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                }

                if let lot, let capacity = lot.capacity {
                    Label("\(capacity) spots", systemImage: "car.fill")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Detail Sections

    private func detailSections(recommendation: ParkingRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Pricing explanation
            PricingExplanationView(
                recommendation: recommendation,
                lot: lot,
                userType: state.profile.effectiveUserType ?? .nonresident,
                isVerifiedResident: state.profile.isVerifiedResident,
                hasPass: state.profile.hasPass,
                startTime: state.parking.effectiveStartTime,
                visitHours: Double(state.parking.visitDurationMinutes) / 60.0,
                enforcementMessage: state.parking.enforcementMessage,
                pricingRules: state.parking.cachedPricingRules
            )
            .padding(.horizontal, 20)
            .sectionAnimation(index: 0, appeared: detailAppeared)

            // Elevation chart
            if let elevations = rawElevations, elevations.count > 2 {
                ElevationChartView(elevations: elevations)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .sectionAnimation(index: 1, appeared: detailAppeared)
            }

            // Rate comparison
            if state.parking.pricingDataLoaded {
                RateComparisonSection(
                    recommendation: recommendation,
                    lot: lot,
                    startTime: state.parking.effectiveStartTime,
                    visitHours: Double(state.parking.visitDurationMinutes) / 60.0,
                    pricingRules: state.parking.cachedPricingRules,
                    tierAssignments: state.parking.cachedTierAssignments,
                    enforcementPeriods: state.parking.cachedEnforcementPeriods,
                    holidays: state.parking.cachedHolidays,
                    userProfile: state.profile
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .sectionAnimation(index: 2, appeared: detailAppeared)
            }

            // Tier change timeline
            if let lot, let history = lot.tierHistory, !history.isEmpty {
                let transitions = TierTransition.from(tierHistory: history)
                if !transitions.isEmpty {
                    TierChangeTimeline(
                        currentTier: recommendation.tier,
                        transitions: transitions
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .sectionAnimation(index: 3, appeared: detailAppeared)
                }
            }

            // Amenities grid
            if let lot {
                AmenitiesGrid(lot: lot, recommendation: recommendation)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .sectionAnimation(index: 4, appeared: detailAppeared)
            }

            // Data freshness footer
            DataFreshnessFooter()
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .sectionAnimation(index: 5, appeared: detailAppeared)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .padding(.top, -24)
        )
    }

    // MARK: - Dismiss Gesture (Vertical)

    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                guard !scrollDismissTriggered else { return }
                let verticalTranslation = value.translation.height
                guard verticalTranslation > 0 else { return }
                guard abs(verticalTranslation) > abs(value.translation.width) else { return }

                morph.isDragging = true
                let progress = min(max(verticalTranslation / 400, 0), 1)
                morph.dismissProgress = progress

                if progress > 0.4 && !dismissHapticFired {
                    dismissHapticFired = true
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } else if progress <= 0.4 {
                    dismissHapticFired = false
                }
            }
            .onEnded { value in
                morph.isDragging = false
                let progress = morph.dismissProgress
                let velocity = value.predictedEndTranslation.height / 400

                if progress + velocity > 0.4 {
                    // Commit dismiss
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.88)) {
                        morph.dismissProgress = 1
                    } completion: {
                        state.closeDetail()
                    }
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        morph.dismissProgress = 0
                    } completion: {
                        scrollDismissTriggered = false
                    }
                }

                dismissHapticFired = false
            }
    }

    // MARK: - Paging Gesture (Horizontal)

    private var pagingGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                // Only trigger if horizontal movement dominates
                guard abs(horizontal) > abs(vertical) * 1.5 else { return }
                guard abs(horizontal) > 80 || abs(value.velocity.width) > 500 else { return }

                let direction: SwipeDirection = horizontal < 0 ? .left : .right
                pageToAdjacentLot(direction: direction)
            }
    }

    private func pageToAdjacentLot(direction: SwipeDirection) {
        guard let currentSlug = morph.fullscreenLotSlug else { return }
        let options = state.parking.displayedOptions
        guard let currentIndex = options.firstIndex(where: { $0.id == currentSlug }) else { return }

        let targetIndex: Int
        switch direction {
        case .left:
            targetIndex = currentIndex + 1
        case .right:
            targetIndex = currentIndex - 1
        }

        guard targetIndex >= 0, targetIndex < options.count else { return }
        let targetOption = options[targetIndex]

        if case .lot(let rec) = targetOption {
            rawElevations = nil
            withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                morph.fullscreenLotSlug = rec.lotSlug
                state.expandedPreviewSlug = rec.lotSlug
                state.selectOption(.lot(rec))
            }
            elevationTask?.cancel()
            elevationTask = Task {
                if let coords = state.parking.walkingRoutes[rec.lotSlug] {
                    rawElevations = await WalkingDirectionsService.fetchRawElevations(coords: coords)
                }
            }
        }
    }
}
