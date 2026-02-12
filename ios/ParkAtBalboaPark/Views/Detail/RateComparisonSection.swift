import SwiftUI

/// Expandable rate comparison showing pricing for different user types.
struct RateComparisonSection: View {
    let recommendation: ParkingRecommendation
    let lot: ParkingLot?
    let startTime: Date
    let visitHours: Double
    let pricingRules: [PricingRule]
    let tierAssignments: [LotTierAssignment]
    let enforcementPeriods: [EnforcementPeriod]
    let holidays: [Holiday]
    let userProfile: UserProfile

    @State private var showAllTypes = false

    private var activeUserType: UserType? {
        userProfile.effectiveUserType
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Rate Comparison", systemImage: "dollarsign.circle")
                .font(.subheadline.weight(.semibold))

            // User's configured roles
            VStack(spacing: 0) {
                ForEach(sortedUserRoles, id: \.self) { role in
                    rateRow(
                        userType: role,
                        isActive: role == activeUserType,
                        showYouBadge: role == activeUserType
                    )

                    if role != sortedUserRoles.last {
                        Divider().padding(.leading, 40)
                    }
                }
            }
            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))

            // Expand to show all user types
            if !showAllTypes {
                Button {
                    withAnimation(.snappy(duration: 0.25)) {
                        showAllTypes = true
                    }
                } label: {
                    HStack {
                        Text("Compare all user types")
                            .font(.caption.weight(.medium))
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
                .sensoryFeedback(.selection, trigger: showAllTypes)
            }

            if showAllTypes {
                VStack(spacing: 0) {
                    ForEach(remainingTypes, id: \.self) { type in
                        rateRow(userType: type, isActive: false, showYouBadge: false)

                        if type != remainingTypes.last {
                            Divider().padding(.leading, 40)
                        }
                    }
                }
                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Rate Row

    private func rateRow(userType: UserType, isActive: Bool, showYouBadge: Bool) -> some View {
        let cost = computeCost(for: userType)

        return HStack {
            Image(systemName: userType.icon)
                .font(.caption)
                .foregroundStyle(isActive ? Color.accentColor : .secondary)
                .frame(width: 24)

            Text(userType.label)
                .font(.subheadline)
                .foregroundStyle(isActive ? .primary : .secondary)

            if showYouBadge {
                Text("You")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor, in: Capsule())
            }

            Spacer()

            Text(cost.costDisplay)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.costColor(cents: cost.costCents, isFree: cost.isFree))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Helpers

    private var sortedUserRoles: [UserType] {
        Array(userProfile.userRoles).sorted { $0.rawValue < $1.rawValue }
    }

    private var remainingTypes: [UserType] {
        UserType.allCases.filter { !userProfile.userRoles.contains($0) }
    }

    private func computeCost(for userType: UserType) -> CostResult {
        guard let lot else {
            return CostResult(
                costCents: recommendation.costCents,
                costDisplay: recommendation.costDisplay,
                isFree: recommendation.isFree,
                tips: []
            )
        }

        let enforced = PricingEngine.isEnforcementActive(
            time: startTime,
            enforcement: enforcementPeriods,
            holidays: holidays
        )

        let tier = PricingEngine.getCurrentTier(
            lotId: lot.id,
            tierAssignments: tierAssignments,
            date: startTime
        )

        let hasPass = userType == activeUserType ? userProfile.hasPass : false

        return PricingEngine.computeLotCost(
            lot: lot,
            tier: tier,
            userType: userType,
            hasPass: hasPass,
            visitHours: visitHours,
            rules: pricingRules,
            enforced: enforced,
            queryDate: startTime
        )
    }
}
