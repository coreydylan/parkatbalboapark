import SwiftUI

struct LotMarkerView: View {
    let label: String
    let tier: LotTier?
    let costColor: Color
    let isSelected: Bool
    let hasTram: Bool
    var isRanked: Bool = false

    private var size: CGFloat {
        if isSelected { return 38 }
        if isRanked { return 32 }
        return 26
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(costColor)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: isSelected ? 3 : 2)
                )
                .shadow(color: costColor.opacity(isRanked ? 0.6 : 0.4), radius: isSelected ? 6 : (isRanked ? 5 : 3))

            Text(label)
                .font(.system(size: isSelected ? 16 : (isRanked ? 14 : 12), weight: .bold))
                .foregroundStyle(.white)
        }
        .animation(.spring(response: 0.3), value: isSelected)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isSelected)
        .accessibilityLabel(
            "\(tier?.name ?? "Parking") lot\(isRanked ? " #\(label)" : "")\(isSelected ? ", selected" : "")\(hasTram ? ", tram available" : "")"
        )
    }
}
