import Foundation

// MARK: - Supporting Types

enum ParkingPassType: String, Codable, CaseIterable, Identifiable {
    case monthly
    case quarterly
    case annual

    var id: String { rawValue }

    var label: String {
        switch self {
        case .monthly: "Monthly"
        case .quarterly: "Quarterly"
        case .annual: "Annual"
        }
    }

    func price(isResident: Bool) -> String {
        switch self {
        case .monthly: isResident ? "$30/mo" : "$40/mo"
        case .quarterly: isResident ? "$60/qtr" : "$120/qtr"
        case .annual: isResident ? "$150/yr" : "$300/yr"
        }
    }
}

enum ParkAffiliation: String, Codable, CaseIterable {
    case staff
    case volunteer
    case none
}

// MARK: - City of San Diego Zip Codes

enum SDCityZipCodes {
    static let all: Set<String> = [
        "92101", "92102", "92103", "92104", "92105", "92106", "92107", "92108",
        "92109", "92110", "92111", "92113", "92114", "92115", "92116", "92117",
        "92119", "92120", "92121", "92122", "92123", "92124", "92126", "92127",
        "92128", "92129", "92130", "92131", "92139", "92154", "92173"
    ]

    static func isSDCity(_ zip: String) -> Bool {
        all.contains(zip)
    }
}

// MARK: - User Profile

@MainActor @Observable
class UserProfile {
    // MARK: - Residency

    var zipCode: String = "" {
        didSet {
            UserDefaults.standard.set(zipCode, forKey: "zipCode")
            if zipCode.count == 5 {
                isSDCityResident = SDCityZipCodes.isSDCity(zipCode)
            }
        }
    }

    var isSDCityResident: Bool = false {
        didSet { UserDefaults.standard.set(isSDCityResident, forKey: "isSDCityResident") }
    }

    var isVerifiedResident: Bool = false {
        didSet { UserDefaults.standard.set(isVerifiedResident, forKey: "isVerifiedResident") }
    }

    // MARK: - Parking Pass

    var hasPass: Bool = false {
        didSet { UserDefaults.standard.set(hasPass, forKey: "hasPass") }
    }

    var passType: ParkingPassType? = nil {
        didSet { UserDefaults.standard.set(passType?.rawValue, forKey: "passType") }
    }

    // MARK: - Affiliation

    var affiliation: ParkAffiliation = .none {
        didSet { UserDefaults.standard.set(affiliation.rawValue, forKey: "affiliation") }
    }

    var selectedOrganization: String? = nil {
        didSet { UserDefaults.standard.set(selectedOrganization, forKey: "selectedOrganization") }
    }

    var isOrgRegistered: Bool = false {
        didSet { UserDefaults.standard.set(isOrgRegistered, forKey: "isOrgRegistered") }
    }

    // MARK: - Accessibility

    var hasADAPlaccard: Bool = false {
        didSet { UserDefaults.standard.set(hasADAPlaccard, forKey: "hasADAPlaccard") }
    }

    // MARK: - App State

    var onboardingComplete: Bool = false {
        didSet { UserDefaults.standard.set(onboardingComplete, forKey: "onboardingComplete") }
    }

    // MARK: - Derived Roles

    var userRoles: Set<UserType> {
        var roles = Set<UserType>()
        if isSDCityResident {
            roles.insert(isVerifiedResident ? .resident : .nonresident)
        } else {
            roles.insert(.nonresident)
        }
        switch affiliation {
        case .staff: roles.insert(.staff)
        case .volunteer: roles.insert(.volunteer)
        case .none: break
        }
        if hasADAPlaccard {
            roles.insert(.ada)
        }
        return roles
    }

    var activeCapacity: UserType? {
        didSet {
            UserDefaults.standard.set(activeCapacity?.rawValue, forKey: "activeCapacity")
        }
    }

    var effectiveUserType: UserType? {
        if let activeCapacity { return activeCapacity }
        // Priority: ada > staff/volunteer > resident/nonresident
        let roles = userRoles
        if roles.contains(.ada) { return .ada }
        if roles.contains(.staff) { return .staff }
        if roles.contains(.volunteer) { return .volunteer }
        if roles.contains(.resident) { return .resident }
        if roles.contains(.nonresident) { return .nonresident }
        return nil
    }

    /// User type sent to the API. Unverified residents are mapped to nonresident
    /// so they see full (non-discounted) pricing from the backend.
    var apiUserType: UserType? {
        guard let effective = effectiveUserType else { return nil }
        if effective == .resident && !isVerifiedResident {
            return .nonresident
        }
        return effective
    }

    // MARK: - Init

    init() {
        loadPersistedState()
    }

    private func loadPersistedState() {
        onboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")
        hasPass = UserDefaults.standard.bool(forKey: "hasPass")
        isVerifiedResident = UserDefaults.standard.bool(forKey: "isVerifiedResident")
        hasADAPlaccard = UserDefaults.standard.bool(forKey: "hasADAPlaccard")
        isOrgRegistered = UserDefaults.standard.bool(forKey: "isOrgRegistered")
        isSDCityResident = UserDefaults.standard.bool(forKey: "isSDCityResident")

        zipCode = UserDefaults.standard.string(forKey: "zipCode") ?? ""
        selectedOrganization = UserDefaults.standard.string(forKey: "selectedOrganization")

        if let passRaw = UserDefaults.standard.string(forKey: "passType"),
           let pass = ParkingPassType(rawValue: passRaw) {
            passType = pass
        }

        if let affRaw = UserDefaults.standard.string(forKey: "affiliation"),
           let aff = ParkAffiliation(rawValue: affRaw) {
            affiliation = aff
        }

        if let capacityRaw = UserDefaults.standard.string(forKey: "activeCapacity"),
           let capacity = UserType(rawValue: capacityRaw) {
            activeCapacity = capacity
        }

        // Migrate from legacy userRoles-based storage
        if onboardingComplete && UserDefaults.standard.data(forKey: "userRoles") != nil {
            migrateFromLegacyRoles()
        }
    }

    private func migrateFromLegacyRoles() {
        guard let rolesData = UserDefaults.standard.data(forKey: "userRoles"),
              let roles = try? JSONDecoder().decode(Set<UserType>.self, from: rolesData)
        else { return }

        if roles.contains(.resident) {
            isSDCityResident = true
        }
        if roles.contains(.staff) {
            affiliation = .staff
        } else if roles.contains(.volunteer) {
            affiliation = .volunteer
        }
        if roles.contains(.ada) {
            hasADAPlaccard = true
        }

        // Clean up legacy key
        UserDefaults.standard.removeObject(forKey: "userRoles")
    }

    // MARK: - Actions

    func completeOnboarding() {
        onboardingComplete = true
    }

    func setActiveCapacity(_ type: UserType?) {
        activeCapacity = type
    }
}
