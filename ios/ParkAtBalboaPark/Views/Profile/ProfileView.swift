import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    var showSetupPrompt: Bool = false

    private var march2Date: Date {
        DateComponents(calendar: .current, year: 2026, month: 3, day: 2).date!
    }

    var body: some View {
        NavigationStack {
            List {
                if showSetupPrompt && state.profile.effectiveUserType == nil {
                    Section {
                        VStack(spacing: 8) {
                            Image(systemName: "car.side.rear.and.collision.and.car.side.front")
                                .font(.largeTitle)
                                .foregroundStyle(Color.accentColor)
                            Text("Welcome to Balboa Park")
                                .font(.headline)
                            Text("Tell us a little about yourself so we can find the best parking options and pricing just for you.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .listRowBackground(Color.clear)
                    }
                }

                Section {
                    ForEach(UserType.allCases) { type in
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundStyle(
                                    state.profile.userRoles.contains(type)
                                        ? Color.accentColor : .secondary
                                )
                                .frame(width: 28)

                            VStack(alignment: .leading) {
                                Text(type.label)
                                    .font(.subheadline.weight(.medium))
                                Text(type.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Toggle(
                                "",
                                isOn: Binding(
                                    get: { state.profile.userRoles.contains(type) },
                                    set: { _ in state.profile.toggleRole(type) }
                                )
                            )
                            .tint(Color.accentColor)
                        }
                    }
                } header: {
                    Text("I am a...")
                } footer: {
                    if state.profile.userRoles.count > 1 {
                        Text(
                            "You can have multiple roles. Select your active role for this visit below."
                        )
                    }
                }

                if state.profile.userRoles.count > 1 {
                    Section("For this visit") {
                        ForEach(
                            Array(state.profile.userRoles).sorted(by: {
                                $0.rawValue < $1.rawValue
                            })
                        ) { role in
                            Button {
                                state.profile.activeCapacity = role
                            } label: {
                                HStack {
                                    Image(systemName: role.icon)
                                    Text(role.label)
                                    Spacer()
                                    if state.profile.activeCapacity == role {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }

                if state.profile.userRoles.contains(.resident) {
                    Section {
                        @Bindable var profile = state.profile
                        Toggle(isOn: $profile.isVerifiedResident) {
                            Label("Verified Resident", systemImage: "checkmark.seal.fill")
                        }
                        .tint(Color.accentColor)
                    } footer: {
                        Text(
                            "Registered with the City of San Diego ($5 one-time fee). Verified residents get 50% off; free at most lots after March 2, 2026."
                        )
                    }

                    Section {
                        @Bindable var profile = state.profile
                        Toggle(isOn: $profile.hasPass) {
                            Label("Parking Pass", systemImage: "creditcard.fill")
                        }
                        .tint(Color.accentColor)
                    } footer: {
                        Text(
                            "If you have a Balboa Park parking pass, all paid lots are free."
                        )
                    }
                }

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
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
