import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
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
