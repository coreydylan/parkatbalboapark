import Foundation

@MainActor @Observable
class UserProfile {
    var userRoles: Set<UserType> = [] {
        didSet { persistUserRoles() }
    }

    var activeCapacity: UserType? {
        didSet {
            UserDefaults.standard.set(activeCapacity?.rawValue, forKey: "activeCapacity")
        }
    }

    var hasPass: Bool = false {
        didSet {
            UserDefaults.standard.set(hasPass, forKey: "hasPass")
        }
    }

    var onboardingComplete: Bool = false {
        didSet { UserDefaults.standard.set(onboardingComplete, forKey: "onboardingComplete") }
    }

    var effectiveUserType: UserType? {
        activeCapacity ?? userRoles.first
    }

    init() {
        loadPersistedState()
    }

    private func loadPersistedState() {
        onboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")
        hasPass = UserDefaults.standard.bool(forKey: "hasPass")

        if let rolesData = UserDefaults.standard.data(forKey: "userRoles"),
            let roles = try? JSONDecoder().decode(Set<UserType>.self, from: rolesData)
        {
            userRoles = roles
        }
        if let capacityRaw = UserDefaults.standard.string(forKey: "activeCapacity"),
            let capacity = UserType(rawValue: capacityRaw)
        {
            activeCapacity = capacity
        }
    }

    private func persistUserRoles() {
        if let data = try? JSONEncoder().encode(userRoles) {
            UserDefaults.standard.set(data, forKey: "userRoles")
        }
    }

    func toggleRole(_ type: UserType) {
        if userRoles.contains(type) {
            userRoles.remove(type)
            if activeCapacity == type {
                activeCapacity = userRoles.first
            }
        } else {
            userRoles.insert(type)
            if activeCapacity == nil {
                activeCapacity = type
            }
        }
    }

    func completeOnboarding() {
        onboardingComplete = true
    }
}
