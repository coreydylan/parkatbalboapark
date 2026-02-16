import SwiftUI

struct ToggleChip: View {
    let label: String
    var icon: String? = nil
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(label)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isActive ? Color.accentColor : Color(.systemGray6))
            )
            .foregroundStyle(isActive ? .white : .primary)
        }
        .sensoryFeedback(.selection, trigger: isActive)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(isActive ? "Selected" : "Not selected")
    }
}
