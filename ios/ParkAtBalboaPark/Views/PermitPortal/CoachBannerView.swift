import SwiftUI

struct CoachBannerView: View {
    let step: PortalStep
    let stepNumber: Int?
    let totalSteps: Int
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: step.icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                if let stepNumber {
                    Text("Step \(stepNumber) of \(totalSteps)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text(step.title)
                    .font(.subheadline.weight(.semibold))

                Text(step.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }
}
