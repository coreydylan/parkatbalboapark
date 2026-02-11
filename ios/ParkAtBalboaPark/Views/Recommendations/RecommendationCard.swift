import SwiftUI

struct RecommendationCard: View {
    let recommendation: ParkingRecommendation
    let rank: Int
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            rankBadge

            // Main content
            VStack(alignment: .leading, spacing: 4) {
                // Lot name + tier
                HStack {
                    Text(recommendation.lotDisplayName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    Spacer()

                    // Cost badge
                    costBadge
                }

                // Details row
                HStack(spacing: 12) {
                    // Walking time
                    if let walkTime = recommendation.walkingTimeDisplay {
                        Label(walkTime, systemImage: "figure.walk")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Tram
                    if recommendation.hasTram {
                        Label("Tram", systemImage: "tram.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    Spacer()

                    // Amenity badges
                    amenityBadges
                }

                // Tips (first tip only in compact view)
                if let tip = recommendation.tips.first {
                    Text(tip)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.green.opacity(0.6) : .clear, lineWidth: 2)
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isSelected)
    }

    // MARK: - Components

    private var rankBadge: some View {
        Text("#\(rank)")
            .font(.caption.weight(.bold))
            .foregroundStyle(rank <= 3 ? .white : .secondary)
            .frame(width: 32, height: 32)
            .background(
                Circle()
                    .fill(rank <= 3 ? Color.green : Color(.systemGray5))
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
            // Check tips for EV charging, ADA
            if recommendation.tips.contains(where: { $0.contains("EV") }) {
                Image(systemName: "ev.plug.ac.type.2")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
            if recommendation.tips.contains(where: { $0.contains("ADA") }) {
                Image(systemName: "accessibility")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
        }
    }
}
