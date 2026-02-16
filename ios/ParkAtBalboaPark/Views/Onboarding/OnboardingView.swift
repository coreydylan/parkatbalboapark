import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var state
    @State private var currentStep: Int = 0

    // MARK: - Local Form State

    @State private var zipCode: String = ""
    @State private var isSDCityResident: Bool = false
    @State private var zipValidated: Bool = false

    @State private var isVerifiedResident: Bool = false
    @State private var verifiedAnswered: Bool = false
    @State private var hasPass: Bool = false
    @State private var passAnswered: Bool = false
    @State private var passType: ParkingPassType = .monthly

    @State private var isStaffOrVolunteer: Bool = false
    @State private var selectedOrg: String? = nil
    @State private var isEmployee: Bool = true
    @State private var isOrgRegistered: Bool = false
    @State private var orgRegisteredAnswered: Bool = false

    @State private var hasADA: Bool = false
    @State private var safariURL: URL?

    // MARK: - Organizations

    private var availableOrganizations: [String] {
        let fromStore = state.parking.organizations.map(\.name)
        return fromStore.isEmpty ? Self.fallbackOrganizations : fromStore
    }

    private static let fallbackOrganizations: [String] = [
        "Comic-Con Museum",
        "Fleet Science Center",
        "Mingei International Museum",
        "Museum of Us",
        "San Diego Air & Space Museum",
        "San Diego Museum of Art",
        "San Diego Natural History Museum",
        "San Diego Zoo Wildlife Alliance",
        "The Old Globe Theatre",
        "Timken Museum of Art",
    ]

    // MARK: - Step Navigation

    /// The steps visible to this user. Non-residents skip step 2 (resident benefits).
    private var visibleSteps: [Int] {
        if isSDCityResident {
            return [1, 2, 3, 4, 5]
        } else {
            return [1, 3, 4, 5]
        }
    }

    /// Index of currentStep in visibleSteps, for progress dots.
    private var progressIndex: Int {
        visibleSteps.firstIndex(of: currentStep) ?? 0
    }

    private var totalProgressSteps: Int {
        visibleSteps.count
    }

    private func goToNextStep() {
        withAnimation(.smooth) {
            if currentStep == 0 {
                currentStep = 1
            } else if let idx = visibleSteps.firstIndex(of: currentStep),
                      idx + 1 < visibleSteps.count {
                currentStep = visibleSteps[idx + 1]
            }
        }
    }

    private func goToPreviousStep() {
        withAnimation(.smooth) {
            if let idx = visibleSteps.firstIndex(of: currentStep), idx > 0 {
                currentStep = visibleSteps[idx - 1]
            } else if currentStep == 1 {
                currentStep = 0
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            Group {
                switch currentStep {
                case 0: welcomeView
                case 1: zipCodeView
                case 2: residentBenefitsView
                case 3: staffVolunteerView
                case 4: adaView
                case 5: summaryView
                default: welcomeView
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.smooth, value: currentStep)
        }
        .sheet(item: $safariURL) { url in
            SafariView(url: url)
                .ignoresSafeArea()
        }
    }

    // MARK: - Progress Dots

    private func progressDots(current: Int, total: Int) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index == current ? Color.accentColor : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == current ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3), value: current)
            }
        }
    }

    // MARK: - Screen 0: Welcome

    private var welcomeView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "tree.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 8) {
                Text("Park at Balboa Park")
                    .font(.title.bold())

                Text("Find the best parking lot based on\nwhere you're going, how long you're\nstaying, and who you are.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: { goToNextStep() }) {
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

    // MARK: - Screen 1: ZIP Code

    private var zipCodeView: some View {
        VStack(spacing: 20) {
            progressDots(current: progressIndex, total: totalProgressSteps)
                .padding(.top, 4)

            Image(systemName: "location.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)
                .padding(.top, 8)

            VStack(spacing: 8) {
                Text("Where do you live?")
                    .font(.title2.bold())

                Text("City of San Diego residents may qualify for discounted parking at Balboa Park.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            TextField("ZIP code", text: $zipCode)
                .keyboardType(.numberPad)
                .font(.title3.monospaced())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.vertical, 12)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                .onChange(of: zipCode) { _, newValue in
                    // Limit to 5 digits
                    let filtered = String(newValue.prefix(5).filter(\.isNumber))
                    if filtered != newValue {
                        zipCode = filtered
                    }
                    // Auto-validate at 5 digits
                    if filtered.count == 5 {
                        withAnimation(.smooth) {
                            isSDCityResident = SDCityZipCodes.isSDCity(filtered)
                            zipValidated = true
                        }
                    } else {
                        withAnimation(.smooth) {
                            zipValidated = false
                        }
                    }
                }

            if zipValidated {
                if isSDCityResident {
                    Label("You're a City of San Diego resident! You may qualify for discounted parking rates.", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    Label("No problem \u{2014} we'll help you find the best parking at the best price.", systemImage: "info.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }

            Text("This is about the City of San Diego specifically, not San Diego County. County residents outside city limits pay visitor rates.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            Spacer()

            VStack(spacing: 12) {
                Button(action: {
                    state.profile.zipCode = zipCode
                    state.profile.isSDCityResident = isSDCityResident
                    goToNextStep()
                }) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!zipValidated)

                Button(action: {
                    zipCode = ""
                    zipValidated = false
                    isSDCityResident = false
                    state.profile.zipCode = ""
                    state.profile.isSDCityResident = false
                    withAnimation(.smooth) {
                        // Skip to staff/volunteer (step 3), bypassing resident benefits
                        currentStep = 3
                    }
                }) {
                    Text("Skip")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 8)
        }
        .padding(24)
        .frame(maxWidth: 380)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 32))
        .padding(20)
    }

    // MARK: - Screen 2: Resident Benefits

    private var residentBenefitsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                progressDots(current: progressIndex, total: totalProgressSteps)
                    .padding(.top, 4)

                VStack(spacing: 8) {
                    Text("Resident Discount")
                        .font(.title2.bold())

                    Text("The kiosks at the lots cannot verify residency \u{2014} everyone pays non-resident rates there. To get the resident discount, you must register online and buy your parking through the city\u{2019}s permit portal before you arrive.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // MARK: Verified Resident Question

                VStack(alignment: .leading, spacing: 12) {
                    Text("Have you registered through the city\u{2019}s permit portal?")
                        .font(.subheadline.weight(.medium))

                    HStack(spacing: 10) {
                        ToggleChip(label: "Yes", isActive: verifiedAnswered && isVerifiedResident) {
                            withAnimation(.smooth) {
                                isVerifiedResident = true
                                verifiedAnswered = true
                            }
                        }
                        ToggleChip(label: "No", isActive: verifiedAnswered && !isVerifiedResident) {
                            withAnimation(.smooth) {
                                isVerifiedResident = false
                                verifiedAnswered = true
                            }
                        }
                    }

                    if verifiedAnswered && !isVerifiedResident {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Register to save up to 50%", systemImage: "tag.fill")
                                .font(.subheadline.bold())

                            Text("Step 1: Create an account at the city\u{2019}s permit portal ($5 one-time fee). Step 2: The first time you purchase a permit or pass, you\u{2019}ll enter your license plate number and upload proof of residency (driver\u{2019}s license, vehicle registration, or utility bill). Verification takes up to 2 business days after that first purchase.")
                                .font(.caption)

                            Button {
                                safariURL = URL(string: "https://sandiego.thepermitportal.com/Register/Create")
                            } label: {
                                Label("Register Now", systemImage: "arrow.up.right.square")
                                    .font(.subheadline.weight(.medium))
                            }

                            Text("You can update this later in Settings once you've registered.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                    }

                    if verifiedAnswered && isVerifiedResident {
                        Label("Great \u{2014} you'll see resident rates throughout the app.", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                            .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                    }
                }

                // MARK: Rate Comparison

                VStack(alignment: .leading, spacing: 8) {
                    Text("Rate Comparison (pre-purchased online)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        rateCard(
                            title: "Verified Resident",
                            icon: "house.fill",
                            rates: ["Level 1: $4\u{2013}$8/day", "Level 2\u{2013}3: $5/day"]
                        )
                        rateCard(
                            title: "At the Kiosk",
                            icon: "dollarsign.square",
                            rates: ["Level 1: $10\u{2013}$16/day", "Level 2\u{2013}3: $10/day"]
                        )
                    }

                    Text("Kiosks can\u{2019}t verify residency. Everyone pays kiosk rates unless you pre-purchase online.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Divider()

                // MARK: Parking Pass Question

                VStack(alignment: .leading, spacing: 12) {
                    Text("Do you have a Balboa Park parking pass?")
                        .font(.subheadline.weight(.medium))

                    HStack(spacing: 10) {
                        ToggleChip(label: "Yes", isActive: passAnswered && hasPass) {
                            withAnimation(.smooth) {
                                hasPass = true
                                passAnswered = true
                            }
                        }
                        ToggleChip(label: "No", isActive: passAnswered && !hasPass) {
                            withAnimation(.smooth) {
                                hasPass = false
                                passAnswered = true
                            }
                        }
                    }

                    if passAnswered && hasPass {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pass type")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 10) {
                                ForEach(ParkingPassType.allCases) { type in
                                    ToggleChip(label: type.label, isActive: passType == type) {
                                        passType = type
                                    }
                                }
                            }

                            Text("Your pass covers all paid lots and metered park roads. Passes are virtual \u{2014} linked to your license plate.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                    }

                    if passAnswered && !hasPass {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Passes cover all paid lots and metered roads inside the park. They\u{2019}re purchased through the city\u{2019}s permit portal ($5 one-time registration required).")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Button {
                                safariURL = URL(string: "https://sandiego.thepermitportal.com/Home/Availability")
                            } label: {
                                Label("Buy a pass", systemImage: "arrow.up.right.square")
                                    .font(.subheadline.weight(.medium))
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                    }
                }

                Button(action: { goToNextStep() }) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .padding(24)
        }
        .frame(maxWidth: 380, maxHeight: 640)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 32))
        .padding(20)
    }

    // MARK: - Rate Card Helper

    private func rateCard(title: String, icon: String, rates: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            ForEach(rates, id: \.self) { rate in
                Text(rate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6).opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Screen 3: Staff / Volunteer

    private var staffVolunteerView: some View {
        ScrollView {
            VStack(spacing: 20) {
                progressDots(current: progressIndex, total: totalProgressSteps)
                    .padding(.top, 4)

                VStack(spacing: 8) {
                    Text("Employees & Volunteers")
                        .font(.title2.bold())

                    Text("Employees and volunteers of qualifying Balboa Park organizations may receive free parking at certain lots.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // MARK: Selection Cards

                VStack(spacing: 12) {
                    selectionCard(
                        title: "Yes",
                        subtitle: "I work or volunteer at a park organization",
                        icon: "building.2.fill",
                        isSelected: isStaffOrVolunteer
                    ) {
                        withAnimation(.smooth) { isStaffOrVolunteer = true }
                    }

                    selectionCard(
                        title: "No",
                        subtitle: "I'm just visiting the park",
                        icon: "figure.walk",
                        isSelected: !isStaffOrVolunteer
                    ) {
                        withAnimation(.smooth) {
                            isStaffOrVolunteer = false
                            selectedOrg = nil
                            orgRegisteredAnswered = false
                        }
                    }
                }

                if isStaffOrVolunteer {
                    VStack(alignment: .leading, spacing: 16) {
                        // MARK: Organization Picker

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Select your organization")
                                .font(.subheadline.weight(.medium))

                            Picker("Organization", selection: $selectedOrg) {
                                Text("Choose one...").tag(nil as String?)
                                ForEach(availableOrganizations, id: \.self) { org in
                                    Text(org).tag(org as String?)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color.accentColor)

                            Text("The City of San Diego has identified these organizations as qualifying for free parking benefits. If your organization is not on this list, it does not qualify.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                        if selectedOrg != nil {
                            // MARK: Role Selection

                            VStack(alignment: .leading, spacing: 8) {
                                Text("What is your role?")
                                    .font(.subheadline.weight(.medium))

                                HStack(spacing: 10) {
                                    ToggleChip(label: "Employee", icon: "briefcase.fill", isActive: isEmployee) {
                                        isEmployee = true
                                    }
                                    ToggleChip(label: "Volunteer", icon: "heart.fill", isActive: !isEmployee) {
                                        isEmployee = false
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))

                            // MARK: Vehicle Registration

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Has your organization registered your vehicle for free parking?")
                                    .font(.subheadline.weight(.medium))

                                HStack(spacing: 10) {
                                    ToggleChip(label: "Yes", isActive: orgRegisteredAnswered && isOrgRegistered) {
                                        withAnimation(.smooth) {
                                            isOrgRegistered = true
                                            orgRegisteredAnswered = true
                                        }
                                    }
                                    ToggleChip(label: "Not yet", isActive: orgRegisteredAnswered && !isOrgRegistered) {
                                        withAnimation(.smooth) {
                                            isOrgRegistered = false
                                            orgRegisteredAnswered = true
                                        }
                                    }
                                }

                                if orgRegisteredAnswered {
                                    if isOrgRegistered {
                                        Label("Free parking at Level 2 and Level 3 lots while you are actively working or volunteering.", systemImage: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                            .transition(.opacity)
                                    } else {
                                        Text("Contact your organization's HR or volunteer coordinator to register your license plate through the Balboa Park Cultural Partnership.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .transition(.opacity)
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }

                Button(action: { goToNextStep() }) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .padding(24)
        }
        .frame(maxWidth: 380, maxHeight: 640)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 32))
        .padding(20)
    }

    // MARK: - Selection Card Helper

    private func selectionCard(
        title: String,
        subtitle: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : Color(.systemGray4))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.accentColor.opacity(0.08) : Color(.systemGray6).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    // MARK: - Screen 4: ADA

    private var adaView: some View {
        VStack(spacing: 20) {
            progressDots(current: progressIndex, total: totalProgressSteps)
                .padding(.top, 4)

            Image(systemName: "accessibility")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)
                .padding(.top, 8)

            VStack(spacing: 8) {
                Text("Accessibility")
                    .font(.title2.bold())

                Text("Do you have a disabled person parking placard or license plate?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                selectionCard(
                    title: "Yes",
                    subtitle: "I have a placard or plate",
                    icon: "accessibility",
                    isSelected: hasADA
                ) {
                    withAnimation(.smooth) { hasADA = true }
                }

                selectionCard(
                    title: "No",
                    subtitle: "I don't have a placard",
                    icon: "xmark.circle",
                    isSelected: !hasADA
                ) {
                    withAnimation(.smooth) { hasADA = false }
                }
            }

            if hasADA {
                Label("You park free in the blue accessible spaces in any lot (no time limit) and at all meters on park roads. If blue spaces are full and you use a regular space, the normal lot rate applies.", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 4)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            Spacer()

            Button(action: { goToNextStep() }) {
                Text("See Your Results")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 8)
        }
        .padding(24)
        .frame(maxWidth: 380)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 32))
        .padding(20)
    }

    // MARK: - Screen 5: Summary

    private var summaryView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.accentColor)

                    Text("Your Parking Profile")
                        .font(.title2.bold())
                }

                // MARK: Profile Summary

                VStack(alignment: .leading, spacing: 12) {
                    summaryRow(icon: "location.fill", label: "Location", value: residencySummary)
                    summaryRow(icon: "building.2.fill", label: "Affiliation", value: affiliationSummary)
                    summaryRow(icon: "accessibility", label: "ADA Placard", value: hasADA ? "Yes" : "No")
                    if hasPass {
                        summaryRow(icon: "creditcard.fill", label: "Parking Pass", value: passType.label)
                    }
                }
                .padding(16)
                .background(Color(.systemGray6).opacity(0.5), in: RoundedRectangle(cornerRadius: 16))

                // MARK: Pricing Breakdown

                VStack(alignment: .leading, spacing: 10) {
                    Text("What You'll Pay")
                        .font(.subheadline.bold())

                    if hasADA {
                        pricingRow(tier: "Blue Spaces (any lot)", price: "Free", highlight: true)
                        pricingRow(tier: "Meters (park roads)", price: "Free", highlight: true)
                        pricingRow(tier: "Regular spaces", price: "Normal rate", highlight: false)
                    } else if hasPass {
                        pricingRow(tier: "All Paid Lots", price: "Included", highlight: true)
                        pricingRow(tier: "Free Lots", price: "Free", highlight: false)
                    } else if isStaffOrVolunteer && isOrgRegistered {
                        pricingRow(tier: "Level 1 Lots", price: isVerifiedResident ? "$5\u{2013}$8/day" : "$10\u{2013}$16/day", highlight: false)
                        pricingRow(tier: "Level 2 Lots", price: "Free", highlight: true)
                        pricingRow(tier: "Level 3 Lots", price: "Free", highlight: true)
                        pricingRow(tier: "Free Lots", price: "Free", highlight: true)
                    } else if isSDCityResident && isVerifiedResident {
                        pricingRow(tier: "Level 1 Lots", price: "$5\u{2013}$8/day", highlight: false)
                        pricingRow(tier: "Level 2 Lots", price: "$5/day", highlight: false)
                        pricingRow(tier: "Level 3 Lots", price: "$5/day", highlight: false)
                        pricingRow(tier: "Free Lots", price: "Free", highlight: true)
                    } else {
                        pricingRow(tier: "Level 1 Lots", price: "$10\u{2013}$16/day", highlight: false)
                        pricingRow(tier: "Level 2 Lots", price: "$10/day", highlight: false)
                        pricingRow(tier: "Level 3 Lots", price: "$10/day", highlight: false)
                        pricingRow(tier: "Free Lots", price: "Free", highlight: true)
                    }
                }
                .padding(16)
                .background(Color(.systemGray6).opacity(0.5), in: RoundedRectangle(cornerRadius: 16))

                // MARK: March 2026 Callout

                if !hasADA && isSDCityResident && isVerifiedResident {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Coming March 2, 2026", systemImage: "calendar.badge.clock")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.accentColor)

                        Text("Seven lots become free for verified residents, and enforcement hours shorten to 8 AM \u{2013} 6 PM.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                }

                // MARK: Enforcement Note

                VStack(alignment: .leading, spacing: 4) {
                    Label("Enforcement Hours", systemImage: "clock.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    Text("Parking is enforced daily 8 AM \u{2013} 8 PM. Free on major holidays.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 4)

                Button(action: commitProfile) {
                    Text("Start Exploring")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
            .padding(24)
        }
        .frame(maxWidth: 380, maxHeight: 640)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 32))
        .padding(20)
    }

    // MARK: - Summary Helpers

    private var residencySummary: String {
        if !isSDCityResident && zipCode.isEmpty {
            return "Not specified"
        } else if isSDCityResident {
            return isVerifiedResident ? "SD Resident (Verified)" : "SD Resident (Unverified)"
        } else {
            return "Visitor"
        }
    }

    private var affiliationSummary: String {
        if isStaffOrVolunteer, let org = selectedOrg {
            let role = isEmployee ? "Employee" : "Volunteer"
            return "\(role) \u{2014} \(org)"
        } else if isStaffOrVolunteer {
            return isEmployee ? "Employee" : "Volunteer"
        } else {
            return "None"
        }
    }

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.medium))
            }

            Spacer()
        }
    }

    private func pricingRow(tier: String, price: String, highlight: Bool) -> some View {
        HStack {
            Text(tier)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(price)
                .font(.caption.bold())
                .foregroundStyle(highlight ? .green : .primary)
        }
    }

    // MARK: - Commit Profile

    private func commitProfile() {
        state.profile.zipCode = zipCode
        state.profile.isSDCityResident = isSDCityResident
        state.profile.isVerifiedResident = isVerifiedResident
        state.profile.hasPass = hasPass
        state.profile.passType = hasPass ? passType : nil
        state.profile.affiliation = isStaffOrVolunteer ? (isEmployee ? .staff : .volunteer) : .none
        state.profile.selectedOrganization = selectedOrg
        state.profile.isOrgRegistered = isOrgRegistered
        state.profile.hasADAPlaccard = hasADA
        state.profile.completeOnboarding()
    }
}

// ToggleChip moved to Views/Components/ToggleChip.swift
