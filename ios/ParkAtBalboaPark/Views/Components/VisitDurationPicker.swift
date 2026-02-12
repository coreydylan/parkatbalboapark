import SwiftUI

struct VisitDurationPicker: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var parking = state.parking

        VStack(alignment: .leading, spacing: 8) {
            Text("Visit Duration")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Picker("Visit Duration", selection: $parking.visitHours) {
                Text("1 hr").tag(1)
                Text("2 hr").tag(2)
                Text("3 hr").tag(3)
                Text("4 hr").tag(4)
                Text("All Day").tag(8)
            }
            .pickerStyle(.segmented)
        }
    }
}
