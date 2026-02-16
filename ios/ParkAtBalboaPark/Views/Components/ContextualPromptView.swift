import SwiftUI

struct ContextualPromptView: View {
    let prompt: ContextualPromptEngine.Prompt
    let onAction: () -> Void
    let onDismiss: () -> Void
    let onSnooze: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: prompt.icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(prompt.title)
                    .font(.subheadline.weight(.semibold))

                Text(prompt.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                HStack(spacing: 12) {
                    if let actionLabel = prompt.actionLabel {
                        Button(actionLabel) {
                            onAction()
                        }
                        .font(.caption.weight(.medium))
                    }

                    if prompt.snoozable, let onSnooze {
                        Button("Later") {
                            onSnooze()
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 4)

            if prompt.dismissable {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 24, height: 24)
                }
            }
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
    }

    private var iconColor: Color {
        switch prompt.iconColor {
        case "red": return .red
        case "orange": return .orange
        case "green": return .green
        default: return .accentColor
        }
    }
}
