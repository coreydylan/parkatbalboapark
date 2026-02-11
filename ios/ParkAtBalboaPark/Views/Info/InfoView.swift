import SwiftUI

struct InfoView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Enforcement section
                Section {
                    HStack {
                        Circle()
                            .fill(state.enforcementActive ? .orange : .green)
                            .frame(width: 10, height: 10)
                        Text(
                            state.enforcementActive
                                ? "Currently enforced" : "Free parking right now"
                        )
                        .font(.subheadline.weight(.medium))
                    }

                    Label("8:00 AM \u{2013} 6:00 PM daily", systemImage: "clock")
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

                // Tram section
                if let tram = state.tramData {
                    Section {
                        Label("Free tram service", systemImage: "tram.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.orange)

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

                        // Stops
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Stops")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)

                            ForEach(
                                tram.stops.sorted(by: { $0.stopOrder < $1.stopOrder })
                            ) { stop in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(.orange)
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

                // About section
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
