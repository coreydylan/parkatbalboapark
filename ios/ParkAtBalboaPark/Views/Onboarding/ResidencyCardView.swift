import SwiftUI

struct ResidencyCardView: View {
    @Environment(AppState.self) private var state
    @Binding var isPresented: Bool

    @State private var phase: CardPhase = .question
    @State private var zipCode = ""
    @State private var zipValidated = false
    @State private var isSDResident = false
    @State private var verifiedChoice: VerifiedChoice?
    @State private var hasPass = false
    @State private var passType: ParkingPassType = .monthly
    @State private var safariURL: URL?

    private enum CardPhase: Equatable {
        case question           // "Do you live in City of San Diego?"
        case zipEntry           // Enter ZIP to confirm
        case nonResident        // "No problem!" confirmation
        case residentFollowUp   // Programs/discounts info
        case verifiedSetup      // Already registered — pass type
        case done               // Auto-dismiss
    }

    private enum VerifiedChoice {
        case tellMeMore
        case alreadyRegistered
        case askLater
    }

    var body: some View {
        VStack(spacing: 16) {
            switch phase {
            case .question:
                questionPhase
            case .zipEntry:
                zipEntryPhase
            case .nonResident:
                nonResidentPhase
            case .residentFollowUp:
                residentFollowUpPhase
            case .verifiedSetup:
                verifiedSetupPhase
            case .done:
                EmptyView()
            }
        }
        .padding(24)
        .frame(maxWidth: 360)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.5, dampingFraction: 0.88), value: phase)
        .sheet(item: $safariURL) { url in
            SafariView(url: url)
                .ignoresSafeArea()
        }
    }

    // MARK: - Phase 1: The Question

    private var questionPhase: some View {
        VStack(spacing: 16) {
            Image(systemName: "tree.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.accentColor)

            Text("Quick question")
                .font(.title3.bold())

            Text("Do you live in the City of San Diego?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                Button {
                    withAnimation(.smooth) { phase = .zipEntry }
                } label: {
                    Text("Yes")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    state.profile.isSDCityResident = false
                    state.profile.residencyCardDismissed = true
                    withAnimation(.smooth) { phase = .nonResident }
                } label: {
                    Text("No")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)

                Button {
                    state.profile.residencyDeferred = true
                    state.profile.residencyCardDismissed = true
                    dismissCard()
                } label: {
                    Text("Skip")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - Phase 1b: ZIP Entry

    private var zipEntryPhase: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.accentColor)

            Text("What's your ZIP code?")
                .font(.title3.bold())

            Text("We'll confirm you're within City of San Diego limits.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("ZIP code", text: $zipCode)
                .keyboardType(.numberPad)
                .font(.title3.monospaced())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.vertical, 12)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                .onChange(of: zipCode) { _, newValue in
                    let filtered = String(newValue.prefix(5).filter(\.isNumber))
                    if filtered != newValue { zipCode = filtered }
                    if filtered.count == 5 {
                        withAnimation(.smooth) {
                            isSDResident = SDCityZipCodes.isSDCity(filtered)
                            zipValidated = true
                        }
                    } else {
                        withAnimation(.smooth) { zipValidated = false }
                    }
                }

            if zipValidated {
                if isSDResident {
                    Label("City of San Diego resident confirmed", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    Label("That ZIP is outside city limits. County residents pay visitor rates.", systemImage: "info.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }

            VStack(spacing: 8) {
                Button {
                    state.profile.zipCode = zipCode
                    state.profile.isSDCityResident = isSDResident
                    state.profile.residencyCardDismissed = true
                    if isSDResident {
                        withAnimation(.smooth) { phase = .residentFollowUp }
                    } else {
                        withAnimation(.smooth) { phase = .nonResident }
                    }
                } label: {
                    Text("Continue")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!zipValidated)

                Button {
                    withAnimation(.smooth) { phase = .question }
                } label: {
                    Text("Back")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Phase 2b: Non-Resident Confirmation

    private var nonResidentPhase: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.thumbsup.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.accentColor)

            Text("You're all set!")
                .font(.title3.bold())

            Text("We'll show you parking options at standard visitor rates. You can always update this in Settings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                dismissCard()
            } label: {
                Text("Start Exploring")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Phase 2a: Resident Follow-Up

    private var residentFollowUpPhase: some View {
        VStack(spacing: 16) {
            Image(systemName: "tag.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.accentColor)

            Text("Resident Discounts")
                .font(.title3.bold())

            Text("The City of San Diego offers discounted parking for registered residents. Would you like to learn more?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                Button {
                    safariURL = URL(string: "https://sandiego.thepermitportal.com/Register/Create")
                } label: {
                    Label("Register at the permit portal", systemImage: "arrow.up.right.square")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    state.profile.isVerifiedResident = true
                    withAnimation(.smooth) { phase = .verifiedSetup }
                } label: {
                    Text("I'm already registered")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)

                Button {
                    dismissCard()
                } label: {
                    Text("Ask me later")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Text("The kiosks at the lots can't verify residency \u{2014} everyone pays full rates there. To get the discount, register online and buy parking through the permit portal before you arrive.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Phase 3: Verified Setup

    private var verifiedSetupPhase: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 36))
                .foregroundStyle(.green)

            Text("Welcome back!")
                .font(.title3.bold())

            Text("Do you have a parking pass?")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ToggleChip(label: "Yes", isActive: hasPass) {
                    withAnimation(.smooth) { hasPass = true }
                }
                ToggleChip(label: "No", isActive: !hasPass) {
                    withAnimation(.smooth) { hasPass = false }
                }
            }

            if hasPass {
                VStack(spacing: 8) {
                    Text("Which type?")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ForEach(ParkingPassType.allCases) { type in
                            ToggleChip(label: type.label, isActive: passType == type) {
                                passType = type
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }

            Button {
                state.profile.hasPass = hasPass
                state.profile.passType = hasPass ? passType : nil
                dismissCard()
            } label: {
                Text("Done")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Actions

    private func dismissCard() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            isPresented = false
        }
    }
}
