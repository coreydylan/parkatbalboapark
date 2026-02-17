import SwiftUI

struct PortalGuideView: View {
    let flow: PortalFlow
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var state

    @State private var mode: Mode = .interstitial
    @State private var currentURL: URL?
    @State private var coachDismissed = false
    @State private var showBrowserOptions = false
    @State private var useCoach = true
    @State private var registrationOnly = false
    @State private var showCompletion = false

    private enum Mode {
        case interstitial
        case preparation
        case web
    }

    var body: some View {
        ZStack {
            switch mode {
            case .interstitial:
                interstitialView
            case .preparation:
                preparationView
            case .web:
                webViewContainer(showCoach: useCoach)
            }

            if showCompletion {
                registrationCompleteOverlay
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Interstitial

    private var interstitialView: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { dismiss() }
                    .font(.subheadline)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Spacer()

            VStack(spacing: 24) {
                Image(systemName: flow.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentColor)

                Text(flow.title)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)

                Text("We can walk you through the steps right here in the app.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Privacy callout
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title3)
                        .foregroundStyle(.green)

                    Text("This website loads in Apple\u{2019}s built-in secure browser \u{2014} the same technology Safari uses. This app cannot see, store, or transmit anything you type. Your information goes directly to the City of San Diego\u{2019}s website.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)

                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        useCoach = true
                        withAnimation(.smooth(duration: 0.3)) { mode = .preparation }
                    } label: {
                        Text("Walk Me Through It")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        useCoach = false
                        withAnimation(.smooth(duration: 0.3)) { mode = .preparation }
                    } label: {
                        Text("Just Show Me the Site")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        showBrowserOptions = true
                    } label: {
                        Label("Open in My Browser", systemImage: "safari")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 32)
            }

            Spacer()
        }
        .confirmationDialog("Open in\u{2026}", isPresented: $showBrowserOptions) {
            Button("Safari") {
                UIApplication.shared.open(flow.url)
                dismiss()
            }
            if let chromeURL, UIApplication.shared.canOpenURL(chromeURL) {
                Button("Chrome") {
                    UIApplication.shared.open(chromeURL)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Preparation

    private var preparationView: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if flow == .registration {
                        registrationPrep
                    } else {
                        purchasePrep
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Before You Start")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Registration Prep

    private var registrationPrep: some View {
        VStack(spacing: 20) {
            // Context line
            Text("This portal is run by ICS, a vendor contracted by the City of San Diego to manage permit parking. The $5 registration fee goes to the vendor.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // The key question
            VStack(spacing: 12) {
                Text("Are you ready to buy a pass today?")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("This matters because the portal bundles residency verification with your first purchase \u{2014} you can\u{2019}t do one without the other.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Option A: Just register (tappable)
            Button {
                registrationOnly = true
                withAnimation(.smooth(duration: 0.3)) { mode = .web }
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Not yet \u{2014} just create an account", systemImage: "person.badge.plus")
                        .font(.subheadline.weight(.semibold))

                    Text("You\u{2019}ll create an account ($5 one-time fee) and can come back to buy a pass later. No vehicle info or documents needed today.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Option B: Register + buy (tappable)
            Button {
                registrationOnly = false
                withAnimation(.smooth(duration: 0.3)) { mode = .web }
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Yes \u{2014} register and buy a pass", systemImage: "ticket.fill")
                        .font(.subheadline.weight(.semibold))

                    Text("Have these ready:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Label("Your vehicle\u{2019}s license plate number", systemImage: "car.fill")
                        Label("Proof of residency: driver\u{2019}s license, vehicle registration, or utility bill", systemImage: "doc.text.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Timeline warning
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("Residency verification may take up to 2 business days. If you\u{2019}re buying a pass for the first time, we recommend purchasing at least 48 hours before you need it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Purchase Prep

    private var purchasePrep: some View {
        VStack(spacing: 20) {
            // Context line
            Text("This portal is run by ICS, a vendor contracted by the City of San Diego. Discounted resident passes can only be purchased here \u{2014} they\u{2019}re not available at the kiosks in the lots.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // First-time buyer callout
            VStack(alignment: .leading, spacing: 8) {
                Label("First time buying?", systemImage: "person.badge.plus")
                    .font(.subheadline.weight(.semibold))

                Text("Your first purchase will also ask you to submit your license plate and proof of residency. Have these ready:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Label("Your vehicle\u{2019}s license plate number", systemImage: "car.fill")
                    Label("Driver\u{2019}s license, vehicle registration, or utility bill", systemImage: "doc.text.fill")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))

            // Timeline warning
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("Residency verification may take up to 2 business days. If this is your first purchase, we recommend buying at least 48 hours before you need parking.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))

            // Returning buyer note
            Text("Already purchased before? Just sign in \u{2014} your vehicle and residency info are on file.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Continue
            Button {
                withAnimation(.smooth(duration: 0.3)) { mode = .web }
            } label: {
                Text("Continue to Portal")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
    }

    // MARK: - Web View Container

    private var activeSteps: [PortalStep] {
        if flow == .registration && registrationOnly {
            return PortalSteps.registrationOnly
        }
        return flow.steps
    }

    private func webViewContainer(showCoach: Bool) -> some View {
        NavigationStack {
            ZStack(alignment: .top) {
                PortalWebView(url: flow.url, currentURL: $currentURL)
                    .ignoresSafeArea(edges: .bottom)

                if showCoach && !coachDismissed {
                    let step = PortalSteps.findStep(for: currentURL, in: activeSteps)
                    let stepNum = PortalSteps.stepNumber(for: step, in: activeSteps)

                    CoachBannerView(
                        step: step,
                        stepNumber: stepNum,
                        totalSteps: activeSteps.count,
                        onDismiss: {
                            withAnimation(.smooth(duration: 0.2)) {
                                coachDismissed = true
                            }
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .navigationTitle(registrationOnly ? "Create Account" : flow.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onChange(of: currentURL) {
            checkForRegistrationCompletion()
        }
    }

    // MARK: - Registration Completion Detection

    private func checkForRegistrationCompletion() {
        guard registrationOnly, let url = currentURL else { return }
        let urlString = url.absoluteString

        // Check if the user has reached a confirmation/success page
        if urlString.range(of: "Confirmation|Success|Dashboard|Home$", options: .regularExpression) != nil {
            state.profile.hasPortalAccount = true
            withAnimation(.smooth(duration: 0.3)) {
                showCompletion = true
            }
        }
    }

    // MARK: - Registration Complete Overlay

    private var registrationCompleteOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)

                Text("You\u{2019}re Registered!")
                    .font(.title2.weight(.bold))

                Text("We\u{2019}ve noted that you created your permit portal account. Next time you search for parking, we\u{2019}ll remind you to purchase your first pass and verify your residency.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Chrome URL

    private var chromeURL: URL? {
        let urlString = flow.url.absoluteString
        guard urlString.hasPrefix("https://") else { return nil }
        let chromeString = "googlechrome://" + urlString.dropFirst("https://".count)
        return URL(string: chromeString)
    }
}
