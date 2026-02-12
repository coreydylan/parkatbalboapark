import SwiftUI

struct RecommendationCard: View {
    let recommendation: ParkingRecommendation
    let rank: Int
    let isSelected: Bool
    var elevationProfile: WalkingDirectionsService.ElevationProfile? = nil

    var body: some View {
        HStack(spacing: 12) {
            rankBadge
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(recommendation.lotDisplayName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    costBadge
                }

                HStack(spacing: 12) {
                    if let walkTime = recommendation.walkingTimeDisplay {
                        Label(walkTime, systemImage: "figure.walk")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let elevation = elevationProfile,
                       elevation.isNotable(distanceMeters: recommendation.walkingDistanceMeters) {
                        Label(
                            "\(Int(elevation.gainMeters * 3.281))ft↑",
                            systemImage: "arrow.up.right"
                        )
                        .font(.caption)
                        .foregroundStyle(elevation.isSteep(distanceMeters: recommendation.walkingDistanceMeters) ? .orange : .secondary)
                    }

                    if recommendation.hasTram {
                        Label("Tram", systemImage: "tram.fill")
                            .font(.caption)
                            .foregroundStyle(Color.tram)
                    }

                    Spacer()
                    amenityBadges
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
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? Color.accentColor.opacity(0.6) : .clear, lineWidth: 2)
                )
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to select this lot")
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

    private var costBadge: some View {
        Text(recommendation.costDisplay)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(recommendation.costColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(recommendation.costColor.opacity(0.12))
            )
    }

    @ViewBuilder
    private var amenityBadges: some View {
        HStack(spacing: 4) {
            if recommendation.tips.contains(where: { $0.contains("EV") }) {
                Image(systemName: "ev.plug.ac.type.2")
                    .font(.caption2)
                    .foregroundStyle(Color.accentColor)
            }
            if recommendation.tips.contains(where: { $0.contains("ADA") }) {
                Image(systemName: "accessibility")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
        }
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        var parts = ["Rank \(rank)", recommendation.lotDisplayName]
        if recommendation.isFree {
            parts.append("Free parking")
        } else {
            parts.append("Cost: \(recommendation.costDisplay)")
        }
        if let walkTime = recommendation.walkingTimeDisplay {
            parts.append("\(walkTime) walk")
        }
        if recommendation.hasTram {
            parts.append("Tram available")
        }
        return parts.joined(separator: ", ")
    }
}
