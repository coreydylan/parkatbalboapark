import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Roles section
                Section {
                    ForEach(UserType.allCases) { type in
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundStyle(
                                    state.userRoles.contains(type) ? .green : .secondary
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
                                    get: { state.userRoles.contains(type) },
                                    set: { _ in state.toggleRole(type) }
                                )
                            )
                            .tint(.green)
                        }
                    }
                } header: {
                    Text("I am a...")
                } footer: {
                    if state.userRoles.count > 1 {
                        Text(
                            "You can have multiple roles. Select your active role for this visit below."
                        )
                    }
                }

                // Active capacity (if multiple roles)
                if state.userRoles.count > 1 {
                    Section("For this visit") {
                        ForEach(
                            Array(state.userRoles).sorted(by: { $0.rawValue < $1.rawValue })
                        ) { role in
                            Button {
                                state.activeCapacity = role
                            } label: {
                                HStack {
                                    Image(systemName: role.icon)
                                    Text(role.label)
                                    Spacer()
                                    if state.activeCapacity == role {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }

                // Parking pass
                if state.userRoles.contains(.resident) {
                    Section {
                        @Bindable var state = state
                        Toggle(isOn: $state.hasPass) {
                            Label("Parking Pass", systemImage: "creditcard.fill")
                        }
                        .tint(.green)
                    } footer: {
                        Text(
                            "If you have a Balboa Park parking pass, all paid lots are free."
                        )
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
