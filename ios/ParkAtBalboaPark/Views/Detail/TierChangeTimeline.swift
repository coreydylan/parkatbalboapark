import SwiftUI

/// Visual timeline showing tier transitions for a parking lot.
struct TierChangeTimeline: View {
    let currentTier: LotTier
    let transitions: [TierTransition]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Level Changes", systemImage: "calendar.badge.clock")
                .font(.subheadline.weight(.semibold))

            VStack(alignment: .leading, spacing: 0) {
                // Current tier
                HStack(spacing: 12) {
                    Circle()
                        .fill(currentTier.color)
                        .frame(width: 10, height: 10)

                    Text("Currently: \(Text(currentTier.name).font(.subheadline.weight(.semibold)).foregroundStyle(currentTier.color))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 14)

                // Transitions
                ForEach(transitions) { transition in
                    VStack(alignment: .leading, spacing: 0) {
                        // Connecting line
                        HStack(spacing: 12) {
                            Rectangle()
                                .fill(.quaternary)
                                .frame(width: 2, height: 20)
                                .padding(.leading, 4)
                            Spacer()
                        }

                        HStack(spacing: 12) {
                            Circle()
                                .fill(transition.isFuture ? Color.accentColor : .secondary)
                                .frame(width: 10, height: 10)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text(formattedDate(transition.dateString))
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(transition.isFuture ? Color.accentColor : .secondary)

                                    if transition.isFuture {
                                        Text("Expected")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 1)
                                            .background(Color.accentColor, in: Capsule())
                                    }
                                }

                                Text("\(transition.fromTier.name) → \(transition.toTier.name)")
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)

                                if let context = contextText(for: transition) {
                                    Text(context)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                    }
                }
            }
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(timelineAccessibilityLabel)
        }
    }

    private var timelineAccessibilityLabel: String {
        var parts = ["Currently \(currentTier.name)"]
        for transition in transitions {
            let date = formattedDate(transition.dateString)
            let status = transition.isFuture ? "Expected" : "Past"
            parts.append("\(status): \(transition.fromTier.name) to \(transition.toTier.name) on \(date)")
        }
        return parts.joined(separator: ". ")
    }

    // MARK: - Helpers

    private func formattedDate(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "America/Los_Angeles")

        guard let date = formatter.date(from: dateStr) else { return dateStr }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM d, yyyy"
        displayFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles")

        return displayFormatter.string(from: date)
    }

    private func contextText(for transition: TierTransition) -> String? {
        // Dropping to tier 0 or 2 means free for verified residents
        if transition.toTier == .free {
            return "Becomes free for all users"
        }
        if transition.toTier == .standard && transition.fromTier == .premium {
            return "Free for verified residents"
        }
        return nil
    }
}
