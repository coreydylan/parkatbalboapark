import SwiftUI

extension Color {
    // MARK: - Cost Colors

    static let costFree = Color("CostFree")
    static let costModerate = Color("CostModerate")
    static let costExpensive = Color("CostExpensive")

    // MARK: - Tier Colors

    static let tierFree = Color("TierFree")
    static let tierPremium = Color("TierPremium")
    static let tierStandard = Color("TierStandard")
    static let tierEconomy = Color("TierEconomy")

    // MARK: - Feature Colors

    static let tram = Color("Tram")
    static let enforcementActive = Color("EnforcementActive")

    // MARK: - Helpers

    static func costColor(cents: Int, isFree: Bool) -> Color {
        if isFree { return .costFree }
        if cents <= 800 { return .costModerate }
        return .costExpensive
    }
}
