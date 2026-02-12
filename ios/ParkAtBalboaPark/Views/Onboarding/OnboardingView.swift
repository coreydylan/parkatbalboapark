import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var state
    @State private var step: OnboardingStep = .welcome

    @State private var isResident = false
    @State private var isNonresident = false
    @State private var isStaff = false
    @State private var isVolunteer = false
    @State private var isADA = false
    @State private var hasParkingPass = false

    enum OnboardingStep {
        case welcome, profile
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            Group {
                switch step {
                case .welcome:
                    welcomeView
                case .profile:
                    profileView
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.smooth, value: step)
        }
    }

    // MARK: - Welcome

    private var welcomeView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "tree.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 8) {
                Text("Park at Balboa Park")
                    .font(.title.bold())

                Text(
                    "Find the best parking lot based on\nwhere you're going, how long you're\nstaying, and who you are."
                )
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: { withAnimation { step = .profile } }) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
        .padding(24)
        .frame(maxWidth: 380)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 32))
        .padding(20)
    }

    // MARK: - Profile Setup

    private var profileView: some View {
        VStack(spacing: 20) {
            Text("About You")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("San Diego resident?")
                        .font(.subheadline.weight(.medium))
                    HStack(spacing: 10) {
                        ToggleChip(label: "Yes", isActive: isResident) {
                            isResident = true
                            isNonresident = false
                        }
                        ToggleChip(label: "No", isActive: isNonresident) {
                            isNonresident = true
                            isResident = false
                        }
                    }
                    if isResident {
                        Toggle("I have a parking pass", isOn: $hasParkingPass)
                            .font(.subheadline)
                            .tint(Color.accentColor)
                            .padding(.top, 4)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Work or volunteer at the park?")
                        .font(.subheadline.weight(.medium))
                    HStack(spacing: 10) {
                        ToggleChip(label: "Staff", icon: "briefcase.fill", isActive: isStaff) {
                            isStaff.toggle()
                        }
                        ToggleChip(
                            label: "Volunteer", icon: "heart.fill", isActive: isVolunteer
                        ) {
                            isVolunteer.toggle()
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("ADA parking placard?")
                        .font(.subheadline.weight(.medium))
                    HStack(spacing: 10) {
                        ToggleChip(label: "Yes", isActive: isADA) {
                            isADA.toggle()
                        }
                        ToggleChip(label: "No", isActive: !isADA) {
                            isADA = false
                        }
                    }
                }
            }

            Spacer()

            Button(action: commitProfile) {
                Text("Start Exploring")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isResident && !isNonresident)
        }
        .padding(24)
        .frame(maxWidth: 380)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 32))
        .padding(20)
    }

    // MARK: - Actions

    private func commitProfile() {
        if isResident { state.profile.toggleRole(.resident) }
        if isNonresident { state.profile.toggleRole(.nonresident) }
        if isStaff { state.profile.toggleRole(.staff) }
        if isVolunteer { state.profile.toggleRole(.volunteer) }
        if isADA { state.profile.toggleRole(.ada) }
        state.profile.hasPass = hasParkingPass
        state.completeOnboarding()
    }
}

// MARK: - Toggle Chip

struct ToggleChip: View {
    let label: String
    var icon: String? = nil
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(label)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isActive ? Color.accentColor : Color(.systemGray6))
            )
            .foregroundStyle(isActive ? .white : .primary)
        }
        .sensoryFeedback(.selection, trigger: isActive)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(isActive ? "Selected" : "Not selected")
    }
}
