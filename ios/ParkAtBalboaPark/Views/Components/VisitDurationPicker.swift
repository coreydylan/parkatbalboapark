import SwiftUI

struct VisitTimePicker: View {
    @Environment(AppState.self) private var state

    /// When true, start time is auto-set and slightly dimmed ("Park Now" flow).
    var isParkNow: Bool = true

    var body: some View {
        @Bindable var parking = state.parking

        VStack(alignment: .leading, spacing: 10) {
            // Time pickers row
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("START")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    DatePicker(
                        "Start",
                        selection: $parking.startTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .opacity(isParkNow ? 0.5 : 1.0)
                    .allowsHitTesting(!isParkNow)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 16)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("END")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    DatePicker(
                        "End",
                        selection: $parking.endTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                }
            }

            // Duration summary
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(parking.visitSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Enforcement message
            if let message = parking.enforcementMessage {
                HStack(spacing: 6) {
                    Image(systemName: enforcementIcon(for: message))
                        .font(.caption2)
                    Text(message)
                        .font(.caption)
                }
                .foregroundStyle(enforcementColor(for: message))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(enforcementColor(for: message).opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }

            // Validation
            if parking.visitDurationMinutes <= 0 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                    Text("End time must be after start time")
                        .font(.caption)
                }
                .foregroundStyle(.red)
            }
        }
        .onChange(of: parking.startTime) { _, newValue in
            parking.startTime = ParkingStore.snapToTenMinutes(newValue)
            if parking.endTime <= parking.startTime {
                parking.endTime = parking.startTime.addingTimeInterval(600)
            }
        }
        .onChange(of: parking.endTime) { _, newValue in
            parking.endTime = ParkingStore.snapToTenMinutes(newValue)
        }
    }

    private func enforcementIcon(for message: String) -> String {
        if message.contains("Holiday") { return "gift.fill" }
        if message.contains("Outside") { return "moon.fill" }
        return "info.circle.fill"
    }

    private func enforcementColor(for message: String) -> Color {
        if message.contains("Holiday") || message.contains("Outside") { return .green }
        return .blue
    }
}
