import SwiftUI

struct InfoView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    private var march2Date: Date {
        DateComponents(calendar: .current, year: 2026, month: 3, day: 2).date!
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Circle()
                            .fill(
                                state.parking.enforcementActive
                                    ? Color.enforcementActive : Color.costFree
                            )
                            .frame(width: 10, height: 10)
                        Text(
                            state.parking.enforcementActive
                                ? "Currently enforced" : "Free parking right now"
                        )
                        .font(.subheadline.weight(.medium))
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        state.parking.enforcementActive
                            ? "Parking is currently enforced"
                            : "Free parking right now"
                    )

                    Label(
                        Date.now >= march2Date
                            ? "8:00 AM \u{2013} 6:00 PM daily"
                            : "8:00 AM \u{2013} 8:00 PM daily",
                        systemImage: "clock"
                    )
                    .font(.subheadline)

                    Label("Free on holidays", systemImage: "calendar")
                        .font(.subheadline)
                } header: {
                    Text("Parking Enforcement")
                } footer: {
                    Text(
                        "Outside enforcement hours, all paid lots are free for everyone."
                    )
                }

                if let tram = state.parking.tramData {
                    Section {
                        Label("Free tram service", systemImage: "tram.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.tram)

                        Label(
                            "\(tram.schedule.startTime) \u{2013} \(tram.schedule.endTime)",
                            systemImage: "clock"
                        )
                        .font(.subheadline)

                        Label(
                            "Every \(tram.schedule.frequencyMinutes) minutes",
                            systemImage: "arrow.triangle.2.circlepath"
                        )
                        .font(.subheadline)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Stops")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)

                            ForEach(
                                tram.stops.sorted(by: { $0.stopOrder < $1.stopOrder })
                            ) { stop in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.tram)
                                        .frame(width: 8, height: 8)
                                    Text(stop.name)
                                        .font(.subheadline)
                                }
                            }
                        }
                    } header: {
                        Text("Free Tram")
                    } footer: {
                        Text(tram.notes)
                    }
                }

                Section {
                    Label("Balboa Park, San Diego", systemImage: "tree.fill")
                        .font(.subheadline)

                    Label("Pricing effective Jan 5, 2026", systemImage: "info.circle")
                        .font(.subheadline)
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
