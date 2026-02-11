import SwiftUI

enum LotTier: Int, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case free = 0
    case premium = 1
    case standard = 2
    case economy = 3

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .free: "Free"
        case .premium: "Premium"
        case .standard: "Standard"
        case .economy: "Economy"
        }
    }

    var color: Color {
        switch self {
        case .free: Color(red: 0x22 / 255.0, green: 0xC5 / 255.0, blue: 0x5E / 255.0)
        case .premium: Color(red: 0xEF / 255.0, green: 0x44 / 255.0, blue: 0x44 / 255.0)
        case .standard: Color(red: 0xF5 / 255.0, green: 0x9E / 255.0, blue: 0x0B / 255.0)
        case .economy: Color(red: 0x3B / 255.0, green: 0x82 / 255.0, blue: 0xF6 / 255.0)
        }
    }
}
