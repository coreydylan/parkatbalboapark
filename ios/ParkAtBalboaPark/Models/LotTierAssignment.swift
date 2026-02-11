import Foundation

struct LotTierAssignment: Codable, Hashable, Sendable {
    let lotId: String
    let tier: LotTier
    let effectiveDate: String
    let endDate: String?
}
