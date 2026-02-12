import SwiftUI

struct StreetMeterCard: View {
    let segment: StreetSegment
    let cost: MeterCostResult
    let isSelected: Bool
    var walkingTimeDisplay: String? = nil
    var elevationProfile: WalkingDirectionsService.ElevationProfile? = nil

    var body: some View {
        HStack(spacing: 12) {
            meterIcon
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(segment.streetName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    costBadge
                }

                HStack(spacing: 12) {
                    if let walkTime = walkingTimeDisplay {
                        Label(walkTime, systemImage: "figure.walk")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let elevation = elevationProfile, elevation.gainMeters >= 3 {
                        Label(
                            "\(Int(elevation.gainMeters * 3.281))ft\u{2191}",
                            systemImage: "arrow.up.right"
                        )
                        .font(.caption)
                        .foregroundStyle(elevation.gainMeters > 15 ? .orange : .secondary)
                    }

                    Label("\(segment.meterCount)", systemImage: "parkingsign.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if segment.hasMobilePay {
                        Image(systemName: "iphone")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }

                    Spacer()

                    if cost.exceedsTimeLimit, let limit = cost.timeLimitDisplay {
                        Label(limit, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                if let tip = cost.tips.first {
                    Text(tip)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .opacity(cost.exceedsTimeLimit ? 0.7 : 1.0)
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
        .accessibilityHint("Double tap to select this meter")
    }

    // MARK: - Components

    private var costColor: Color {
        Color.costColor(cents: cost.costCents, isFree: cost.isFree)
    }

    private var meterIcon: some View {
        Image(systemName: "parkingsign.circle.fill")
            .font(.title3.weight(.bold))
            .foregroundStyle(costColor)
            .frame(width: 32, height: 32)
    }

    private var costBadge: some View {
        Text(cost.costDisplay)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(costColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(costColor.opacity(0.12))
            )
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        var parts = ["Street meter", segment.streetName]
        if cost.isFree {
            parts.append("Free parking")
        } else {
            parts.append("Cost: \(cost.costDisplay)")
        }
        if let walkTime = walkingTimeDisplay {
            parts.append("\(walkTime) walk")
        }
        parts.append("\(segment.meterCount) meter\(segment.meterCount == 1 ? "" : "s")")
        if cost.exceedsTimeLimit {
            parts.append("Warning: visit exceeds time limit")
        }
        return parts.joined(separator: ", ")
    }
}
