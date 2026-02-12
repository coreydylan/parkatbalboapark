import SwiftUI

struct LotMarkerView: View {
    let label: String
    let tier: LotTier?
    let costColor: Color
    let isSelected: Bool
    let hasTram: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(costColor)
                .frame(width: isSelected ? 36 : 26, height: isSelected ? 36 : 26)
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: isSelected ? 3 : 2)
                )
                .shadow(color: costColor.opacity(0.4), radius: isSelected ? 6 : 3)

            Text(label)
                .font(.system(size: isSelected ? 16 : 12, weight: .bold))
                .foregroundStyle(.white)
        }
        .animation(.spring(response: 0.3), value: isSelected)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isSelected)
        .accessibilityLabel(
            "\(tier?.name ?? "Parking") lot\(isSelected ? ", selected" : "")\(hasTram ? ", tram available" : "")"
        )
    }
}
