import Foundation

enum UserType: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case resident
    case nonresident
    case staff
    case volunteer
    case ada

    var id: String { rawValue }

    var label: String {
        switch self {
        case .resident: "Resident"
        case .nonresident: "Visitor"
        case .staff: "Staff"
        case .volunteer: "Volunteer"
        case .ada: "ADA"
        }
    }

    /// SF Symbol name for this user type.
    var icon: String {
        switch self {
        case .resident: "house.fill"
        case .nonresident: "airplane"
        case .staff: "briefcase.fill"
        case .volunteer: "heart.fill"
        case .ada: "accessibility"
        }
    }

    var description: String {
        switch self {
        case .resident:
            "San Diego residents. Verified residents get discounted rates."
        case .nonresident:
            "Visitors and tourists pay standard parking rates"
        case .staff:
            "Balboa Park staff members with valid credentials"
        case .volunteer:
            "Registered volunteers at Balboa Park institutions"
        case .ada:
            "Holders of valid ADA placards or disabled parking permits"
        }
    }
}
