import MapKit
import SwiftUI

/// In-sheet lot detail card that fills the sheet space with a Look Around
/// background, gradient overlay, and key lot information.
struct LotDetailCard: View {
    @Environment(AppState.self) private var state
    let recommendation: ParkingRecommendation

    @State private var snapshotImage: UIImage?
    @State private var showDirectionsSheet = false
    @State private var showAllRates = false
    @State private var portalFlow: PortalFlow?

    private var lot: ParkingLot? {
        state.parking.lotLookup[recommendation.lotSlug]
    }

    private let photoFraction: CGFloat = 0.4

    var body: some View {
        GeometryReader { geo in
            let photoHeight = geo.size.height * photoFraction

            ZStack(alignment: .top) {
                // Base: solid dark background
                Color(.systemBackground)
                    .environment(\.colorScheme, .dark)

                // Photo at top only
                photoHeader(height: photoHeight)

                // Content overlaid: fixed title + scrollable details
                contentOverlay(photoHeight: photoHeight)
            }
        }
        .frame(maxHeight: .infinity)
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: 16,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 16
        ))
        .ignoresSafeArea(edges: .bottom)
        .overlay(alignment: .top) {
            Capsule()
                .fill(.white.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
        }
        .overlay(alignment: .topTrailing) {
            Button {
                state.closeDetail()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .white.opacity(0.3))
            }
            .padding(12)
        }
        .overlay(alignment: .topLeading) {
            Button {
                state.closeDetail()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(.white.opacity(0.2), in: Circle())
            }
            .padding(12)
        }
        .fullScreenCover(item: $portalFlow) { flow in
            PortalGuideView(flow: flow)
        }
        .confirmationDialog("Get Directions", isPresented: $showDirectionsSheet) {
            Button("Apple Maps") {
                DirectionsHelper.openAppleMaps(
                    to: recommendation.coordinate,
                    name: recommendation.lotDisplayName
                )
            }
            Button("Google Maps") {
                DirectionsHelper.openGoogleMaps(to: recommendation.coordinate)
            }
            Button("Cancel", role: .cancel) {}
        }
        .task {
            if let scene = await LookAroundService.fetchScene(
                lat: recommendation.lat,
                lng: recommendation.lng
            ) {
                snapshotImage = await LookAroundService.fetchSnapshot(
                    scene: scene,
                    size: CGSize(width: 500, height: 800)
                )
            }
        }
    }

    // MARK: - Photo Header

    private func photoHeader(height: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            if let image = snapshotImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: height)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.4),
                        Color.accentColor.opacity(0.15),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: height)
                .overlay {
                    Image(systemName: "car.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.white.opacity(0.1))
                }
            }

            // Fade from photo into dark background (soft, gradual)
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: Color(.systemBackground).opacity(0.15), location: 0.3),
                    .init(color: Color(.systemBackground).opacity(0.5), location: 0.6),
                    .init(color: Color(.systemBackground).opacity(0.85), location: 0.8),
                    .init(color: Color(.systemBackground), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: height * 0.7)
            .environment(\.colorScheme, .dark)
        }
        .frame(height: height)
        .allowsHitTesting(false)
    }

    // MARK: - Content Overlay

    private func contentOverlay(photoHeight: CGFloat) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Transparent spacer — photo shows through here
                Color.clear
                    .frame(height: photoHeight - 48)

                // Opaque content block — prevents photo bleeding between items
                VStack(alignment: .leading, spacing: 10) {
                    // Lot name
                    Text(recommendation.lotDisplayName)
                        .font(.title2.weight(.bold))
                        .lineLimit(2)

                    // Address
                    if let lot {
                        Text(lot.address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    // Stats + amenity chips
                    statsAndAmenityRow

                    // Cost + enforcement status
                    costAndEnforcementSection

                    // Special rules callout
                    specialRulesCallout

                    // Pricing explanation
                    if state.parking.pricingDataLoaded, let explanation = pricingExplanation {
                        Text(explanation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(3)
                    }

                    // Rate comparison
                    if state.parking.pricingDataLoaded {
                        rateComparisonSection
                    }

                    // Payment info
                    paymentInfo

                    // Buy permit link for verified residents at paid lots
                    if !recommendation.isFree && state.profile.isVerifiedResident {
                        Button {
                            portalFlow = .purchase
                        } label: {
                            Label("Buy a day permit (resident rate)", systemImage: "arrow.up.right.square")
                                .font(.caption.weight(.medium))
                        }
                    }

                    // Directions button
                    Button {
                        showDirectionsSheet = true
                    } label: {
                        Label(
                            "Get Directions",
                            systemImage: "arrow.triangle.turn.up.right.diamond.fill"
                        )
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.accentColor)
                    .padding(.top, 4)
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .environment(\.colorScheme, .dark)
    }

    // MARK: - Stats + Amenity Row

    private var statsAndAmenityRow: some View {
        // Wrap in a flexible layout so pills flow to next line if needed
        WrappingHStack(spacing: 6) {
            if let walkTime = recommendation.walkingTimeDisplay {
                statPill(icon: "figure.walk", text: walkTime)
            }

            if let elevation = state.parking.elevationProfiles[recommendation.lotSlug],
                elevation.isNotable(distanceMeters: recommendation.walkingDistanceMeters)
            {
                statPill(
                    icon: "arrow.up.right",
                    text: "\(Int(elevation.gainMeters * 3.281))ft\u{2191}",
                    highlight: elevation.isSteep(
                        distanceMeters: recommendation.walkingDistanceMeters)
                )
            }

            if recommendation.hasTram {
                statPill(icon: "tram.fill", text: "Tram", color: Color.tram)
            }

            if let lot, let capacity = lot.capacity {
                statPill(icon: "car.2.fill", text: "\(capacity) spots")
            }

            // Amenity chips
            if let lot {
                if lot.hasEvCharging {
                    statPill(icon: "ev.plug.ac.type.2", text: "EV")
                }
                if lot.hasAdaSpaces {
                    statPill(icon: "accessibility", text: "ADA")
                }
            }
        }
    }

    private func statPill(
        icon: String, text: String, color: Color? = nil, highlight: Bool = false
    ) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.medium))
            .foregroundStyle(highlight ? .orange : (color ?? .secondary))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary, in: Capsule())
    }

    // MARK: - Cost + Enforcement

    private var costAndEnforcementSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                if recommendation.isFree {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                }
                Text(recommendation.costDisplay)
                    .font(.title.weight(.bold))
            }
            .foregroundStyle(recommendation.costColor)

            // Enforcement status
            if let enfMsg = state.parking.enforcementMessage {
                Label(enfMsg, systemImage: "clock")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
            } else if state.parking.enforcementActive {
                Label(enforcementTimeRange, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 2)
    }

    private var enforcementTimeRange: String {
        let (start, end) = ParkingStore.enforcementWindow(
            for: state.parking.effectiveStartTime)
        let startStr = ParkingStore.formatHour(start)
        let endStr = ParkingStore.formatHour(end)
        return "Enforced \(startStr)–\(endStr)"
    }

    // MARK: - Special Rules

    @ViewBuilder
    private var specialRulesCallout: some View {
        if let lot, let rules = lot.specialRules {
            let activeRules = rules.filter { $0.freeMinutes > 0 }
            if let rule = activeRules.first {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                    Text(rule.description)
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.green.opacity(0.9), in: Capsule())
            }
        }
    }

    // MARK: - Rate Comparison

    private var rateComparisonSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            Button {
                withAnimation(.snappy(duration: 0.2)) {
                    showAllRates.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle")
                        .font(.caption)
                    Text("Compare rates")
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Image(systemName: showAllRates ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }

            if showAllRates {
                VStack(spacing: 0) {
                    ForEach(UserType.allCases, id: \.self) { type in
                        rateRow(for: type)
                        if type != UserType.allCases.last {
                            Divider()
                                .background(.white.opacity(0.15))
                                .padding(.leading, 32)
                        }
                    }
                }
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func rateRow(for userType: UserType) -> some View {
        let cost = computeCost(for: userType)
        let isCurrentUser = userType == state.profile.effectiveUserType

        return HStack(spacing: 8) {
            Image(systemName: userType.icon)
                .font(.caption2)
                .foregroundStyle(isCurrentUser ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.tertiary))
                .frame(width: 18)

            Text(userType.label)
                .font(.caption)
                .foregroundStyle(isCurrentUser ? .primary : .secondary)

            if isCurrentUser {
                Text("You")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Color.accentColor, in: Capsule())
            }

            Spacer()

            Text(cost.costDisplay)
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    Color.costColor(cents: cost.costCents, isFree: cost.isFree))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func computeCost(for userType: UserType) -> CostResult {
        guard let lot else {
            return CostResult(
                costCents: recommendation.costCents,
                costDisplay: recommendation.costDisplay,
                isFree: recommendation.isFree,
                tips: []
            )
        }

        let enforced = PricingEngine.isEnforcementActive(
            time: state.parking.effectiveStartTime,
            enforcement: state.parking.cachedEnforcementPeriods,
            holidays: state.parking.cachedHolidays
        )

        let tier = PricingEngine.getCurrentTier(
            lotId: lot.id,
            tierAssignments: state.parking.cachedTierAssignments,
            date: state.parking.effectiveStartTime
        )

        let hasPass =
            userType == state.profile.effectiveUserType ? state.profile.hasPass : false

        return PricingEngine.computeLotCost(
            lot: lot,
            tier: tier,
            userType: userType,
            hasPass: hasPass,
            visitHours: Double(state.parking.visitDurationMinutes) / 60.0,
            rules: state.parking.cachedPricingRules,
            enforced: enforced,
            queryDate: state.parking.effectiveStartTime
        )
    }

    // MARK: - Payment Info

    private var paymentInfo: some View {
        HStack(spacing: 4) {
            Image(systemName: "creditcard")
                .font(.caption2)
            Text("ParkMobile, Card, Apple Pay, Google Pay")
                .font(.caption)
        }
        .foregroundStyle(.tertiary)
    }

    // MARK: - Pricing Explanation

    private var pricingExplanation: String? {
        let rule = PricingEngine.findPricingRule(
            tier: recommendation.tier,
            userType: state.profile.effectiveUserType,
            rules: state.parking.cachedPricingRules,
            date: state.parking.effectiveStartTime
        )

        let specialTip = lot?.specialRules?.first(where: { $0.freeMinutes > 0 })?.description

        let text = PricingExplanationEngine.explain(
            lotName: recommendation.lotDisplayName,
            tier: recommendation.tier,
            userType: state.profile.effectiveUserType,
            isVerifiedResident: state.profile.isVerifiedResident,
            costCents: recommendation.costCents,
            costDisplay: recommendation.costDisplay,
            isFree: recommendation.isFree,
            startTime: state.parking.effectiveStartTime,
            visitHours: Double(state.parking.visitDurationMinutes) / 60.0,
            enforcementMessage: state.parking.enforcementMessage,
            hasPass: state.profile.hasPass,
            specialRuleTip: specialTip,
            pricingRule: rule
        )

        return text.isEmpty ? nil : text
    }
}

// MARK: - Wrapping HStack (flow layout for pills)

/// Simple flow layout that wraps children to the next line when they exceed width.
private struct WrappingHStack: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            guard index < result.positions.count else { continue }
            let pos = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return LayoutResult(
            positions: positions,
            size: CGSize(width: maxWidth, height: y + rowHeight)
        )
    }

    private struct LayoutResult {
        let positions: [CGPoint]
        let size: CGSize
    }
}
