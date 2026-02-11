import SwiftUI

struct VisitDurationPicker: View {
    @Environment(AppState.self) private var state

    private let options: [(label: String, hours: Int)] = [
        ("1 hr", 1),
        ("2 hr", 2),
        ("3 hr", 3),
        ("4 hr", 4),
        ("All Day", 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Visit Duration")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(options, id: \.hours) { option in
                    Button(option.label) {
                        state.visitHours = option.hours
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(state.visitHours == option.hours ? Color.green : Color(.systemGray6))
                    )
                    .foregroundStyle(state.visitHours == option.hours ? .white : .primary)
                    .sensoryFeedback(.selection, trigger: state.visitHours)
                }
            }
        }
    }
}
