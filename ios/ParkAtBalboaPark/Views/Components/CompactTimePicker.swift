import SwiftUI

/// A compact single-row time picker (~44pt) showing start → end, duration pill, and enforcement status.
/// Replaces the taller VisitTimePicker in the recommendation sheet header.
struct CompactTimePicker: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var parking = state.parking

        HStack(spacing: 8) {
            // Start time picker
            DatePicker(
                "Start",
                selection: $parking.startTime,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .scaleEffect(0.85, anchor: .trailing)
            .frame(width: 76)

            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            // End time picker
            DatePicker(
                "End",
                selection: $parking.endTime,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .scaleEffect(0.85, anchor: .leading)
            .frame(width: 76)

            // Duration pill
            durationPill

            Spacer(minLength: 0)

            // Enforcement status
            enforcementPill
        }
        .frame(height: 44)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Visit time picker")
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

    // MARK: - Duration Pill

    private var durationPill: some View {
        let totalMinutes = state.parking.visitDurationMinutes
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60

        let text: String
        if hours > 0 && mins > 0 {
            text = "\(hours)h \(mins)m"
        } else if hours > 0 {
            text = "\(hours)h"
        } else {
            text = "\(mins)m"
        }

        return Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.quaternary.opacity(0.6), in: Capsule())
    }

    // MARK: - Enforcement Pill

    @ViewBuilder
    private var enforcementPill: some View {
        if state.parking.visitDurationMinutes <= 0 {
            HStack(spacing: 3) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                Text("Invalid")
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(.red)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.red.opacity(0.1), in: Capsule())
        } else if let message = state.parking.enforcementMessage {
            HStack(spacing: 3) {
                Image(systemName: enforcementIcon(for: message))
                    .font(.caption2)
                Text(enforcementLabel(for: message))
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(enforcementColor(for: message))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(enforcementColor(for: message).opacity(0.1), in: Capsule())
        }
    }

    // MARK: - Enforcement Helpers

    private func enforcementIcon(for message: String) -> String {
        if message.contains("Holiday") { return "gift.fill" }
        if message.contains("Outside") { return "moon.fill" }
        if message.contains("Free after") || message.contains("Free before") { return "info.circle.fill" }
        return "info.circle.fill"
    }

    private func enforcementLabel(for message: String) -> String {
        if message.contains("Holiday") { return "Holiday" }
        if message.contains("Outside") { return "Free" }
        if message.contains("Free after") {
            // Extract time: "Free after 6 PM" → "Free after 6 PM"
            return message
        }
        if message.contains("Free before") {
            return message
        }
        return "Enforced"
    }

    private func enforcementColor(for message: String) -> Color {
        if message.contains("Holiday") || message.contains("Outside") || message.contains("Free") {
            return .green
        }
        return .blue
    }
}
