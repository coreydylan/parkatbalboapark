import SwiftUI

/// Displays a natural-language pricing explanation sentence.
struct PricingExplanationView: View {
    let recommendation: ParkingRecommendation
    let lot: ParkingLot?
    let userType: UserType
    let isVerifiedResident: Bool
    let hasPass: Bool
    let startTime: Date
    let visitHours: Double
    let enforcementMessage: String?
    let pricingRules: [PricingRule]

    private var explanation: String {
        let rule = PricingEngine.findPricingRule(
            tier: recommendation.tier,
            userType: userType,
            rules: pricingRules,
            date: startTime
        )

        let specialTip: String? = lot?.specialRules?.first(where: { sr in
            sr.freeMinutes > 0
        })?.description

        return PricingExplanationEngine.explain(
            lotName: recommendation.lotDisplayName,
            tier: recommendation.tier,
            userType: userType,
            isVerifiedResident: isVerifiedResident,
            costCents: recommendation.costCents,
            costDisplay: recommendation.costDisplay,
            isFree: recommendation.isFree,
            startTime: startTime,
            visitHours: visitHours,
            enforcementMessage: enforcementMessage,
            hasPass: hasPass,
            specialRuleTip: specialTip,
            pricingRule: rule
        )
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "quote.opening")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)

            Text(explanation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pricing explanation: \(explanation)")
    }
}
