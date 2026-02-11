import Foundation

enum DurationType: String, Codable, Hashable, Sendable {
    case hourly
    case daily
    case event
}

struct PricingRule: Codable, Identifiable, Hashable, Sendable {
    let tier: LotTier
    let userType: UserType
    let durationType: DurationType
    let rateCents: Int
    let maxDailyCents: Int?
    let effectiveDate: String
    let endDate: String?

    var id: String { "\(tier.rawValue)-\(userType.rawValue)-\(durationType.rawValue)-\(effectiveDate)" }

    init(
        tier: LotTier,
        userType: UserType,
        durationType: DurationType,
        rateCents: Int,
        maxDailyCents: Int?,
        effectiveDate: String,
        endDate: String?
    ) {
        self.tier = tier
        self.userType = userType
        self.durationType = durationType
        self.rateCents = rateCents
        self.maxDailyCents = maxDailyCents
        self.effectiveDate = effectiveDate
        self.endDate = endDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tier = try container.decode(LotTier.self, forKey: .tier)
        userType = try container.decode(UserType.self, forKey: .userType)
        durationType = try container.decode(DurationType.self, forKey: .durationType)
        rateCents = try container.decode(Int.self, forKey: .rateCents)
        maxDailyCents = try container.decodeIfPresent(Int.self, forKey: .maxDailyCents)
        effectiveDate = (try? container.decode(String.self, forKey: .effectiveDate)) ?? ""
        endDate = try container.decodeIfPresent(String.self, forKey: .endDate)
    }
}
