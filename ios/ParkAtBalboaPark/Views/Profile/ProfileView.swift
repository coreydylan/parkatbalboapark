import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var showResetAlert = false

    private var march2Date: Date {
        DateComponents(calendar: .current, year: 2026, month: 3, day: 2).date!
    }

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

    var body: some View {
        NavigationStack {
            List {
                introSection
                profileSummarySection
                residencySection
                parkingPassSection
                affiliationSection
                accessibilitySection
                activeRoleSection
                enforcementSection
                tramSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                        state.refreshIfProfileChanged()
                    }
                }
            }
            .alert("Reset Onboarding", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) {
                    resetProfile()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will clear all your settings and show the onboarding flow again.")
            }
        }
    }

    // MARK: - Intro

    @ViewBuilder
    private var introSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Balboa Park has a complicated parking system with different rates depending on who you are \u{2014} where you live, where you work, and whether you have a permit or pass.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Tell us about yourself below. Select everything that applies and we\u{2019}ll automatically find the cheapest parking option for wherever you\u{2019}re headed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Text("How This Works")
        }
    }

    // MARK: - Section 1: Profile Summary

    @ViewBuilder
    private var profileSummarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(profileSummaryText)
                    .font(.subheadline.weight(.medium))

                ForEach(
                    Array(state.profile.userRoles).sorted(by: { $0.rawValue < $1.rawValue })
                ) { role in
                    Label(role.label, systemImage: role.icon)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if state.profile.hasADAPlaccard {
                    Label("Free parking at all lots", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.costFree)
                }

                if state.profile.hasPass {
                    Label("Parking pass covers all paid lots", systemImage: "creditcard.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.costFree)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Profile Summary")
        }
    }

    private var profileSummaryText: String {
        let profile = state.profile

        if profile.hasADAPlaccard {
            return "ADA Placard Holder \u{2014} You park free at every lot in the park."
        }

        var parts: [String] = []

        if profile.isSDCityResident {
            if profile.isVerifiedResident {
                parts.append("Verified San Diego Resident \u{2014} discounted rates")
            } else {
                parts.append("San Diego Resident (not yet verified \u{2014} currently paying visitor rates)")
            }
        } else {
            parts.append("Visitor \u{2014} standard rates")
        }

        switch profile.affiliation {
        case .staff:
            if profile.isOrgRegistered {
                parts.append("Park Staff \u{2014} free at Level 2 & Level 3 lots")
            } else {
                parts.append("Park Staff \u{2014} vehicle not registered (no free parking yet)")
            }
        case .volunteer:
            if profile.isOrgRegistered {
                parts.append("Volunteer \u{2014} free at Level 2 & Level 3 lots")
            } else {
                parts.append("Volunteer \u{2014} vehicle not registered (no free parking yet)")
            }
        case .none:
            break
        }

        return parts.joined(separator: "\n")
    }

    // MARK: - Section 2: Residency

    @ViewBuilder
    private var residencySection: some View {
        Section {
            NavigationLink {
                ZipCodeEditView()
            } label: {
                HStack {
                    Text("ZIP Code")
                    Spacer()
                    Text(state.profile.zipCode.isEmpty ? "Not set" : state.profile.zipCode)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Label("City of San Diego Resident", systemImage: state.profile.isSDCityResident
                    ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundStyle(state.profile.isSDCityResident ? .primary : .secondary)
                Spacer()
                Image(
                    systemName: state.profile.isSDCityResident
                        ? "checkmark.circle.fill" : "xmark.circle"
                )
                .foregroundStyle(state.profile.isSDCityResident ? .green : .secondary)
            }

            if state.profile.isSDCityResident {
                @Bindable var profile = state.profile
                Toggle(isOn: $profile.isVerifiedResident) {
                    Label("Verified Resident", systemImage: "checkmark.seal.fill")
                }
                .tint(Color.accentColor)
            }

            if state.profile.isSDCityResident && !state.profile.isVerifiedResident {
                Button {
                    if let url = URL(string: "https://sandiego.thepermitportal.com/") {
                        openURL(url)
                    }
                } label: {
                    Label("Register at the city\u{2019}s permit portal", systemImage: "arrow.up.right.square")
                        .foregroundStyle(Color.accentColor)
                }
            }
        } header: {
            Text("Residency")
        } footer: {
            Text(residencyFooterText)
        }
    }

    private var residencyFooterText: String {
        if state.profile.isSDCityResident && !state.profile.isVerifiedResident {
            return "Even though you live in San Diego, you\u{2019}re currently paying the same rates as visitors. The city requires a one-time $5 registration at their permit portal to unlock resident pricing. You\u{2019}ll need your license plate and a driver\u{2019}s license, vehicle registration, or utility bill. Once approved (1\u{2013}2 business days), you\u{2019}ll save up to 50% at paid lots."
        } else if state.profile.isSDCityResident && state.profile.isVerifiedResident {
            return "You\u{2019}re registered with the city and getting discounted resident rates at paid lots. Starting March 2, 2026, seven lots become completely free for verified residents and enforcement hours shorten to 8 AM \u{2013} 6 PM."
        } else {
            return "Balboa Park\u{2019}s resident discount program is only for people who live within City of San Diego limits \u{2014} not the broader San Diego County. If you live in places like Chula Vista, La Mesa, or Poway, visitor rates apply. Your ZIP code determines eligibility automatically."
        }
    }

    // MARK: - Section 3: Parking Pass

    @ViewBuilder
    private var parkingPassSection: some View {
        Section {
            @Bindable var profile = state.profile
            Toggle(isOn: $profile.hasPass) {
                Label("I have a parking pass", systemImage: "creditcard.fill")
            }
            .tint(Color.accentColor)

            if state.profile.hasPass {
                Picker("Pass Type", selection: passTypeBinding) {
                    ForEach(ParkingPassType.allCases) { passType in
                        Text(passType.label).tag(passType)
                    }
                }
                .pickerStyle(.segmented)
            }
        } header: {
            Text("Parking Pass")
        } footer: {
            Text(parkingPassFooterText)
        }
    }

    private var passTypeBinding: Binding<ParkingPassType> {
        Binding(
            get: { state.profile.passType ?? .monthly },
            set: { state.profile.passType = $0 }
        )
    }

    private var parkingPassFooterText: String {
        if state.profile.hasPass {
            return "A parking pass lets you park at any paid lot without paying per visit. It also covers metered park roads. Passes are purchased separately through the City of San Diego \u{2014} this app just needs to know if you have one so we can show you accurate pricing."
        } else if state.profile.isSDCityResident {
            return "If you park at Balboa Park regularly, a pass can save you money. Passes cover all paid lots and metered roads. Resident passes start at $30/month ($60/quarter, $150/year). You can purchase one at sandiego.thepermitportal.com."
        } else {
            return "If you park at Balboa Park regularly, a pass can save you money. Passes cover all paid lots and metered roads. Visitor passes start at $40/month ($120/quarter, $300/year). You can purchase one at sandiego.thepermitportal.com."
        }
    }

    // MARK: - Section 4: Park Affiliation

    @ViewBuilder
    private var affiliationSection: some View {
        Section {
            @Bindable var profile = state.profile
            Picker(selection: $profile.affiliation) {
                Text("Employee").tag(ParkAffiliation.staff)
                Text("Volunteer").tag(ParkAffiliation.volunteer)
                Text("Neither").tag(ParkAffiliation.none)
            } label: {
                Label("Affiliation", systemImage: "building.2")
            }
            .pickerStyle(.menu)

            if state.profile.affiliation != .none {
                Picker("Organization", selection: organizationBinding) {
                    Text("Select...").tag("")
                    ForEach(availableOrganizations, id: \.self) { org in
                        Text(org).tag(org)
                    }
                }
                .pickerStyle(.menu)

                Toggle(isOn: $profile.isOrgRegistered) {
                    Label("Vehicle registered for free parking", systemImage: "car.fill")
                }
                .tint(Color.accentColor)
            }
        } header: {
            Text("Employees & Volunteers")
        } footer: {
            Text(affiliationFooterText)
        }
    }

    private var affiliationFooterText: String {
        if state.profile.affiliation != .none {
            if state.profile.isOrgRegistered {
                return "With a registered vehicle, you get free parking at Level 2 and Level 3 lots (like Pepper Grove, Federal Building, and Inspiration Point) while you\u{2019}re actively working or volunteering. Level 1 lots near the center of the park (like the Alcazar, Organ Pavilion, and Space Theater) still require payment \u{2014} the free parking benefit does not cover those."
            } else {
                return "To get free parking, your organization needs to register your vehicle\u{2019}s license plate through the Balboa Park Cultural Partnership (BPCP). Ask your HR department or volunteer coordinator \u{2014} they handle the registration. Until your vehicle is registered, you\u{2019}ll pay regular rates."
            }
        } else {
            return "The City of San Diego and the Balboa Park Cultural Partnership have identified specific organizations \u{2014} museums, theaters, and cultural institutions with leaseholds in the park \u{2014} whose employees and volunteers qualify for free parking at certain lots (not all lots). If your organization isn\u{2019}t on the list, it hasn\u{2019}t been designated as qualifying."
        }
    }

    private var organizationBinding: Binding<String> {
        Binding(
            get: { state.profile.selectedOrganization ?? "" },
            set: { newValue in
                state.profile.selectedOrganization = newValue.isEmpty ? nil : newValue
            }
        )
    }

    // MARK: - Section 5: Accessibility

    @ViewBuilder
    private var accessibilitySection: some View {
        Section {
            @Bindable var profile = state.profile
            Toggle(isOn: $profile.hasADAPlaccard) {
                Label("Disabled person placard or plate", systemImage: "accessibility")
            }
            .tint(Color.accentColor)
        } header: {
            Text("Accessibility")
        } footer: {
            if state.profile.hasADAPlaccard {
                Text(
                    "Balboa Park policy: vehicles displaying a valid disabled person placard or plate park free at every lot in the park, at all times. You are not limited to designated blue accessible spaces \u{2014} you may use any available space in any lot."
                )
            } else {
                Text(
                    "If you have a California disabled person parking placard (hanging or dashboard) or a disabled person license plate, turn this on. It overrides all other pricing \u{2014} you\u{2019}ll park free everywhere in the park."
                )
            }
        }
    }

    // MARK: - Section 6: Active Role

    @ViewBuilder
    private var activeRoleSection: some View {
        if state.profile.userRoles.count > 1 {
            Section {
                ForEach(
                    Array(state.profile.userRoles).sorted(by: { $0.rawValue < $1.rawValue })
                ) { role in
                    Button {
                        state.profile.setActiveCapacity(role)
                    } label: {
                        HStack {
                            Image(systemName: role.icon)
                                .frame(width: 24)
                            Text(role.label)
                            Spacer()
                            if state.profile.activeCapacity == role
                                || (state.profile.activeCapacity == nil
                                    && state.profile.effectiveUserType == role)
                            {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            } header: {
                Text("Parking as\u{2026}")
            } footer: {
                Text("You qualify for multiple designations, and each one has different parking rates. Choose which one to use when we calculate prices. For example, if you\u{2019}re a resident but also a park employee, your staff rate might be better at some lots but your resident rate might be better at others.")
            }
        }
    }

    // MARK: - Section 7: Parking Enforcement

    @ViewBuilder
    private var enforcementSection: some View {
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
                "Balboa Park parking is only enforced during these hours. Outside enforcement hours \u{2014} early mornings, evenings, and holidays \u{2014} every lot in the park is free for everyone, regardless of residency or permits."
            )
        }
    }

    // MARK: - Section 8: Free Tram

    @ViewBuilder
    private var tramSection: some View {
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
    }

    // MARK: - Section 9: About

    @ViewBuilder
    private var aboutSection: some View {
        Section {
            Label("Balboa Park, San Diego", systemImage: "tree.fill")
                .font(.subheadline)

            Label("Pricing effective Jan 5, 2026", systemImage: "info.circle")
                .font(.subheadline)

            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                Label("Reset onboarding", systemImage: "arrow.counterclockwise")
                    .font(.subheadline)
            }
        } header: {
            Text("About")
        }
    }

    // MARK: - Helpers

    private func resetProfile() {
        state.profile.zipCode = ""
        state.profile.isSDCityResident = false
        state.profile.isVerifiedResident = false
        state.profile.hasPass = false
        state.profile.passType = nil
        state.profile.affiliation = .none
        state.profile.selectedOrganization = nil
        state.profile.isOrgRegistered = false
        state.profile.hasADAPlaccard = false
        state.profile.activeCapacity = nil
        state.profile.onboardingComplete = false
        state.showOnboarding = true
        dismiss()
    }
}

// MARK: - ZIP Code Edit Sub-View

struct ZipCodeEditView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var zipCode: String = ""

    var body: some View {
        Form {
            Section {
                TextField("ZIP Code", text: $zipCode)
                    .keyboardType(.numberPad)
                    .textContentType(.postalCode)
                    .onChange(of: zipCode) { _, newValue in
                        // Limit to 5 digits
                        let filtered = String(newValue.prefix(5).filter(\.isNumber))
                        if filtered != newValue {
                            zipCode = filtered
                        }
                    }
            } header: {
                Text("Enter your ZIP code")
            } footer: {
                if zipCode.count == 5 {
                    if SDCityZipCodes.isSDCity(zipCode) {
                        Label(
                            "This is a City of San Diego ZIP code. You qualify for resident rates.",
                            systemImage: "checkmark.circle.fill"
                        )
                        .foregroundStyle(.green)
                    } else {
                        Label(
                            "This is not a City of San Diego ZIP code. Visitor rates apply.",
                            systemImage: "info.circle"
                        )
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("ZIP Code")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    state.profile.zipCode = zipCode
                    dismiss()
                }
                .disabled(zipCode.isEmpty)
            }
        }
        .onAppear {
            zipCode = state.profile.zipCode
        }
    }
}
