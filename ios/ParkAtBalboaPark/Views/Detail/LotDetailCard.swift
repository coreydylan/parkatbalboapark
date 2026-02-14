import MapKit
import SwiftUI

/// In-sheet lot detail card that fills the sheet space with a Look Around
/// background, gradient overlay, and key lot information.
struct LotDetailCard: View {
    @Environment(AppState.self) private var state
    let recommendation: ParkingRecommendation

    @State private var snapshotImage: UIImage?
    @State private var showDirectionsSheet = false

    private var lot: ParkingLot? {
        state.parking.lotLookup[recommendation.lotSlug]
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Layer 1: Background image or gradient
            backgroundLayer

            // Layer 2: Gradient overlay for text readability
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black.opacity(0.1), location: 0.15),
                    .init(color: .black.opacity(0.45), location: 0.4),
                    .init(color: .black.opacity(0.8), location: 0.7),
                    .init(color: .black.opacity(0.95), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            // Layer 3: Content
            contentOverlay
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

    // MARK: - Background

    @ViewBuilder
    private var backgroundLayer: some View {
        if let image = snapshotImage {
            GeometryReader { geo in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
        } else {
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.4),
                    Color.accentColor.opacity(0.15),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                Image(systemName: "car.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white.opacity(0.1))
            }
        }
    }

    // MARK: - Content Overlay

    private var contentOverlay: some View {
        VStack(alignment: .leading, spacing: 10) {
            Spacer(minLength: 0)

            // Lot name
            Text(recommendation.lotDisplayName)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)

            // Address
            if let lot {
                Text(lot.address)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }

            // Stats row
            statsRow

            // Cost
            costDisplay

            // Pricing explanation
            if state.parking.pricingDataLoaded, let explanation = pricingExplanation {
                Text(explanation)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)
            }

            // First tip
            if let tip = recommendation.tips.first {
                Label(tip, systemImage: "lightbulb.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
            }

            // Directions button
            Button {
                showDirectionsSheet = true
            } label: {
                Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .foregroundStyle(.black)
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .padding(.top, 12)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 8) {
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

            Spacer()
        }
    }

    private func statPill(
        icon: String, text: String, color: Color = .white, highlight: Bool = false
    ) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.medium))
            .foregroundStyle(highlight ? .orange : color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.white.opacity(0.15), in: Capsule())
    }

    // MARK: - Cost Display

    private var costDisplay: some View {
        HStack(spacing: 8) {
            if recommendation.isFree {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
            }
            Text(recommendation.costDisplay)
                .font(.title.weight(.bold))
        }
        .foregroundStyle(recommendation.isFree ? .green : .white)
        .padding(.top, 2)
    }

    // MARK: - Pricing Explanation

    private var pricingExplanation: String? {
        let rule = PricingEngine.findPricingRule(
            tier: recommendation.tier,
            userType: state.profile.effectiveUserType ?? .nonresident,
            rules: state.parking.cachedPricingRules,
            date: state.parking.effectiveStartTime
        )

        let specialTip = lot?.specialRules?.first(where: { $0.freeMinutes > 0 })?.description

        let text = PricingExplanationEngine.explain(
            lotName: recommendation.lotDisplayName,
            tier: recommendation.tier,
            userType: state.profile.effectiveUserType ?? .nonresident,
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
