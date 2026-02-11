import SwiftUI

struct CostBadge: View {
    let costDisplay: String
    let costCents: Int
    let isFree: Bool

    var color: Color {
        if isFree { return .green }
        if costCents <= 800 { return .orange }
        return .red
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
    }
}
