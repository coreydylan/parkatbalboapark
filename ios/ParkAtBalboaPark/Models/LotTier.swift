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
        case .premium: "Level 1"
        case .standard: "Level 2"
        case .economy: "Level 3"
        }
    }

    var color: Color {
        switch self {
        case .free: .tierFree
        case .premium: .tierPremium
        case .standard: .tierStandard
        case .economy: .tierEconomy
        }
    }
}
