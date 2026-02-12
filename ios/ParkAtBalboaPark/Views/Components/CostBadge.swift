import SwiftUI

struct CostBadge: View {
    let costDisplay: String
    let costCents: Int
    let isFree: Bool

    private var color: Color {
        Color.costColor(cents: costCents, isFree: isFree)
    }

    var body: some View {
        HStack(spacing: 4) {
            if isFree {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
            }
            Text(costDisplay)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.12), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isFree ? "Free parking" : "Cost: \(costDisplay)")
    }
}
