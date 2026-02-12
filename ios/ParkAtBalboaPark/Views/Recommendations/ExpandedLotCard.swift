import MapKit
import SwiftUI

/// Mid-expanded card that shows Look Around imagery + key data inline in the list.
/// Step 2 of the 3-step card progression: compact → expanded → full detail.
struct ExpandedLotCard: View {
    @Environment(AppState.self) private var state
    let recommendation: ParkingRecommendation
    let rank: Int
    var elevationProfile: WalkingDirectionsService.ElevationProfile? = nil

    @State private var lookAroundScene: MKLookAroundScene?
    @State private var appeared = false

    private var lot: ParkingLot? {
        state.parking.lotLookup[recommendation.lotSlug]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Look Around / fallback header with overlay
            ZStack(alignment: .bottom) {
                Group {
                    if let scene = lookAroundScene {
                        LookAroundPreview(initialScene: scene)
                            .frame(height: 200)
                    } else {
                        fallbackHeader
                            .frame(height: 140)
                    }
                }

                // Gradient overlay from bottom
                LinearGradient(
                    colors: [.clear, .clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Overlaid info
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        // Tier badge
                        Text(recommendation.tier.name)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(recommendation.tier.color.opacity(0.9), in: Capsule())

                        Text(recommendation.lotDisplayName)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        if let lot {
                            Text(lot.address)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Large cost
                    Text(recommendation.costDisplay)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(recommendation.isFree ? .green : .white)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 16, bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0, topTrailingRadius: 16
                )
            )

            // Stats row below the image
            HStack(spacing: 14) {
                if let walkTime = recommendation.walkingTimeDisplay {
                    Label(walkTime, systemImage: "figure.walk")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                if let elevation = elevationProfile,
                   elevation.isNotable(distanceMeters: recommendation.walkingDistanceMeters) {
                    Label(
                        "\(Int(elevation.gainMeters * 3.281))ft↑",
                        systemImage: "arrow.up.right"
                    )
                    .font(.caption.weight(.medium))
                    .foregroundStyle(elevation.isSteep(distanceMeters: recommendation.walkingDistanceMeters) ? .orange : .secondary)
                }

                if recommendation.hasTram {
                    Label("Tram", systemImage: "tram.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.tram)
                }

                if let lot, let capacity = lot.capacity {
                    Label("\(capacity)", systemImage: "car.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Details arrow
                HStack(spacing: 4) {
                    Text("Details")
                        .font(.caption.weight(.semibold))
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(Color.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, recommendation.tips.first != nil ? 4 : 12)

            // Tip / pricing hint
            if let tip = recommendation.tips.first {
                Text(tip)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accentColor.opacity(0.4), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .opacity(appeared ? 1 : 0.8)
        .scaleEffect(appeared ? 1 : 0.97)
        .task {
            withAnimation(.easeOut(duration: 0.25)) {
                appeared = true
            }
            lookAroundScene = await LookAroundService.fetchScene(
                lat: recommendation.lat,
                lng: recommendation.lng
            )
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: appeared)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to view full details")
    }

    // MARK: - Fallback

    private var fallbackHeader: some View {
        LinearGradient(
            colors: [
                recommendation.tier.color.opacity(0.4),
                recommendation.tier.color.opacity(0.15),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Image(systemName: "car.fill")
                .font(.largeTitle)
                .foregroundStyle(.white.opacity(0.2))
        }
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        var parts = ["Expanded preview", "Rank \(rank)", recommendation.lotDisplayName]
        if recommendation.isFree {
            parts.append("Free parking")
        } else {
            parts.append("Cost: \(recommendation.costDisplay)")
        }
        if let walkTime = recommendation.walkingTimeDisplay {
            parts.append("\(walkTime)")
        }
        if recommendation.hasTram {
            parts.append("Tram available")
        }
        return parts.joined(separator: ", ")
    }
}
