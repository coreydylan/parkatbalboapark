import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var showResetAlert = false
    @State private var portalFlow: PortalFlow?

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
                profileSummarySection

                // Primary identity section — shown prominently based on user type
                if state.profile.hasADAPlaccard {
                    accessibilitySection
                }
                if state.profile.affiliation != .none {
                    affiliationSection
                }

                residencySection

                // Parking pass: show for SD residents or anyone who has one
                if state.profile.isSDCityResident || state.profile.hasPass {
                    parkingPassSection
                }

                activeRoleSection
                enforcementSection
                tramSection
                moreOptionsSection
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
            .fullScreenCover(item: $portalFlow) { flow in
                PortalGuideView(flow: flow)
            }
            .alert("Reset All Settings", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) {
                    resetProfile()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will clear all your settings. You'll see the setup prompt again next time you open the app.")
            }
        }
    }

    // MARK: - Profile Summary

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
                    Label("Free at blue spaces in lots + all park meters", systemImage: "checkmark.circle.fill")
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
            return "ADA Placard Holder \u{2014} Free at blue spaces in lots and all meters on park roads."
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
                    portalFlow = .registration
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
            return "Important: the parking kiosks at the lots cannot verify residency. If you just show up and pay at a kiosk, you\u{2019}ll pay full non-resident rates even though you live here. To get the resident discount: Step 1 \u{2014} create an account at the city\u{2019}s permit portal ($5 one-time fee). Step 2 \u{2014} purchase a permit or pass. During your first purchase you\u{2019}ll enter your license plate and upload proof of residency (driver\u{2019}s license, vehicle registration, or utility bill). Verification takes 1\u{2013}2 business days after that first purchase."
        } else if state.profile.isSDCityResident && state.profile.isVerifiedResident {
            return "You\u{2019}re registered and can pre-purchase parking at resident rates through the permit portal. Remember: the kiosks at the lots cannot verify residency, so always buy your permit online before you arrive. Starting March 2, 2026, seven lots become completely free for verified residents."
        } else {
            return "Balboa Park\u{2019}s resident discount is only for people who live within City of San Diego limits \u{2014} not the broader San Diego County. If you live in places like Chula Vista, La Mesa, or Poway, visitor rates apply. Non-residents pay at the kiosks in the lots or can buy passes online."
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

                // Permit expiration
                DatePicker(
                    "Expires",
                    selection: permitExpirationBinding,
                    displayedComponents: .date
                )

                permitStatusRow
            }

            if !state.profile.hasPass {
                passPricingGrid

                Button {
                    portalFlow = .purchase
                } label: {
                    Label("Buy a pass or day permit", systemImage: "arrow.up.right.square")
                        .foregroundStyle(Color.accentColor)
                }

                if state.profile.isVerifiedResident {
                    HStack {
                        Label("Day permits this month", systemImage: "ticket")
                            .font(.subheadline)
                        Spacer()
                        Text("\(state.profile.dayPermitCount)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        state.profile.recordDayPermitPurchase()
                    } label: {
                        Label("Record a day permit purchase", systemImage: "plus.circle")
                            .font(.subheadline)
                    }
                }
            }
        } header: {
            Text("Parking Pass")
        } footer: {
            Text(parkingPassFooterText)
        }
    }

    @ViewBuilder
    private var passPricingGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("")
                    .frame(width: 70, alignment: .leading)
                Text("Resident")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Text("Non-Res")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }

            ForEach(ParkingPassType.allCases) { passType in
                HStack {
                    Text(passType.label)
                        .font(.caption.weight(.medium))
                        .frame(width: 70, alignment: .leading)
                    Text(passType.price(isResident: true))
                        .font(.caption)
                        .foregroundStyle(state.profile.isSDCityResident ? Color.accentColor : .secondary)
                        .frame(maxWidth: .infinity)
                    Text(passType.price(isResident: false))
                        .font(.caption)
                        .foregroundStyle(state.profile.isSDCityResident ? .secondary : Color.accentColor)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var passTypeBinding: Binding<ParkingPassType> {
        Binding(
            get: { state.profile.passType ?? .monthly },
            set: { state.profile.passType = $0 }
        )
    }

    private var permitExpirationBinding: Binding<Date> {
        Binding(
            get: { state.profile.permitExpirationDate ?? Calendar.current.date(byAdding: .month, value: 1, to: Date())! },
            set: { state.profile.permitExpirationDate = $0 }
        )
    }

    @ViewBuilder
    private var permitStatusRow: some View {
        switch state.profile.permitState {
        case .expired:
            HStack {
                Label("Expired", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.red)
                Spacer()
                Button("Renew") {
                    portalFlow = .purchase
                }
                .font(.subheadline)
            }
        case .expiringSoon:
            HStack {
                let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: state.profile.permitExpirationDate ?? Date()).day ?? 0
                Label("Expires in \(daysLeft) day\(daysLeft == 1 ? "" : "s")", systemImage: "clock.badge.exclamationmark")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.orange)
                Spacer()
                Button("Renew") {
                    portalFlow = .purchase
                }
                .font(.subheadline)
            }
        case .active:
            Label("Active", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.green)
        default:
            EmptyView()
        }
    }

    private var parkingPassFooterText: String {
        if state.profile.hasPass {
            return "Your pass covers all paid lots and metered park roads (not 6th Ave/Park Blvd meters or Zoo lots). Passes are virtual \u{2014} tied to your license plate, no physical tag. This app just needs to know you have one so we can show you accurate pricing."
        } else if state.profile.isSDCityResident {
            return "The permit portal also sells single-day permits at resident rates (e.g. $4 half-day or $8/day at Level 1 lots, $5/day at Level 2 & 3). These must be purchased online before your visit \u{2014} the kiosks at the lots only charge non-resident rates. If you visit often, a monthly pass ($30) is cheaper than buying day permits. You\u{2019}ll need a portal account first ($5 one-time fee to register)."
        } else {
            return "Passes cover all paid lots and metered roads inside the park. They\u{2019}re virtual (tied to your license plate) and purchased through the city\u{2019}s permit portal. You\u{2019}ll need a portal account first ($5 one-time fee to register). You enter your plate number and upload residency docs during your first purchase. Non-residents pay at the kiosks for single visits, or buy a pass for regular visits."
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
                    "With a valid placard or plate, you park free in the designated blue accessible spaces in any parking lot, with no time limit. You also park free at any metered spot on roads in and near the park. However, if all blue spaces are taken and you park in a regular space in a lot, the normal lot rate applies."
                )
            } else {
                Text(
                    "If you have a disabled person parking placard or license plate, turn this on. You\u{2019}ll get free parking in blue accessible spaces in lots (no time limit) and at all meters on park roads. Note: regular (non-blue) spaces in lots still require payment."
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

    // MARK: - More Options (discovery for hidden sections)

    @ViewBuilder
    private var moreOptionsSection: some View {
        // Only show if there are discoverable sections currently hidden
        if state.profile.affiliation == .none || !state.profile.hasADAPlaccard || (!state.profile.isSDCityResident && !state.profile.hasPass) {
            Section {
                if state.profile.affiliation == .none {
                    @Bindable var profile = state.profile
                    Button {
                        withAnimation {
                            profile.affiliation = .staff
                        }
                    } label: {
                        Label("I work or volunteer at a park organization", systemImage: "building.2")
                            .font(.subheadline)
                    }
                }

                if !state.profile.hasADAPlaccard {
                    @Bindable var profile = state.profile
                    Toggle(isOn: $profile.hasADAPlaccard) {
                        Label("I have a disability placard or plate", systemImage: "accessibility")
                            .font(.subheadline)
                    }
                    .tint(Color.accentColor)
                }

                if !state.profile.isSDCityResident && !state.profile.hasPass {
                    Button {
                        portalFlow = .purchase
                    } label: {
                        Label("Buy a parking pass", systemImage: "creditcard")
                            .font(.subheadline)
                    }
                }
            } header: {
                Text("More Options")
            }
        }
    }

    // MARK: - About

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
                Label("Reset all settings", systemImage: "arrow.counterclockwise")
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
        state.profile.residencyCardDismissed = false
        state.profile.residencyDeferred = false
        state.profile.permitExpirationDate = nil
        state.profile.permitReminderSnoozedUntil = nil
        state.profile.dayPermitCount = 0
        state.profile.dayPermitCountResetDate = nil
        state.profile.visitCount = 0
        state.profile.lastVisitDate = nil
        state.profile.appOpenCount = 0
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
