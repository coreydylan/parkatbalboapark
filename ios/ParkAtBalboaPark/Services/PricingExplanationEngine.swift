import Foundation

/// Generates natural-language pricing explanation sentences for the detail view.
enum PricingExplanationEngine {

    /// Generate a contextual pricing explanation sentence.
    ///
    /// Examples:
    /// - "At 4:00 PM on a Tuesday, the Alcazar Parking Structure is $5 for up to 4 hours
    ///    for City of San Diego residents with a verified resident account."
    /// - "The Pepper Grove Lot is free for everyone — this lot is always free."
    /// - "At 10:30 PM on a Tuesday, the Alcazar Parking Structure is free because parking
    ///    enforcement is not active outside enforcement hours."
    static func explain(
        lotName: String,
        tier: LotTier,
        userType: UserType,
        isVerifiedResident: Bool,
        costCents: Int,
        costDisplay: String,
        isFree: Bool,
        startTime: Date,
        visitHours: Double,
        enforcementMessage: String?,
        hasPass: Bool,
        specialRuleTip: String?,
        pricingRule: PricingRule?
    ) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        timeFormatter.timeZone = PricingEngine.pacificTimeZone

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        dayFormatter.timeZone = PricingEngine.pacificTimeZone

        let timeStr = timeFormatter.string(from: startTime)
        let dayStr = dayFormatter.string(from: startTime)
        let timePrefix = "At \(timeStr) on a \(dayStr)"

        let userDesc = userTypeDescription(userType, isVerifiedResident: isVerifiedResident)

        // Free tier — always free
        if tier == .free {
            return "The \(lotName) is free for everyone — this lot is always free."
        }

        // Holiday or outside enforcement
        if let enfMsg = enforcementMessage {
            if enfMsg.contains("Holiday") {
                let holidayName = extractHolidayName(enfMsg)
                return "\(timePrefix), the \(lotName) is free — \(holidayName ?? "it's a holiday") and parking enforcement is not active."
            }
            if enfMsg.contains("Outside") {
                return "\(timePrefix), the \(lotName) is free because parking enforcement is not active outside enforcement hours."
            }
        }

        // Pass holder
        if hasPass && isFree {
            return "\(timePrefix), the \(lotName) is free for \(userDesc) with an active parking pass."
        }

        // Special rule (e.g. first 3 hours free)
        if isFree, let tip = specialRuleTip {
            return "\(timePrefix), the \(lotName) is free — \(tip.lowercased())."
        }

        // Staff/volunteer free at non-premium tiers
        if isFree && (userType == .staff || userType == .volunteer) && tier != .premium {
            return "\(timePrefix), the \(lotName) is free for Balboa Park \(userType.label.lowercased()) at \(tier.name) lots."
        }

        // ADA free (in designated blue spaces)
        if isFree && userType == .ada {
            return "\(timePrefix), the blue accessible spaces at the \(lotName) are free with a valid placard or plate. Regular spaces are subject to the standard lot rate."
        }

        // Generic free (resident at free tiers after March 2)
        if isFree {
            return "\(timePrefix), the \(lotName) is free for \(userDesc)."
        }

        // Paid — use pricing rule info for specifics
        if let rule = pricingRule {
            switch rule.durationType {
            case .block:
                if visitHours <= 4 {
                    return "\(timePrefix), the \(lotName) is \(costDisplay) for up to 4 hours for \(userDesc)."
                } else if let maxDaily = rule.maxDailyCents {
                    return "\(timePrefix), the \(lotName) is \(PricingEngine.formatCost(maxDaily)) for the day for \(userDesc) (visits over 4 hours)."
                }
            case .hourly:
                let rateDisplay = PricingEngine.formatCost(rule.rateCents)
                if let maxDaily = rule.maxDailyCents, costCents >= maxDaily {
                    return "\(timePrefix), the \(lotName) is \(costDisplay) (daily maximum) for \(userDesc) at \(rateDisplay)/hr."
                }
                return "\(timePrefix), the \(lotName) is \(costDisplay) for \(userDesc) at \(rateDisplay)/hr."
            case .daily:
                return "\(timePrefix), the \(lotName) is \(costDisplay) (flat daily rate) for \(userDesc)."
            case .event:
                return "\(timePrefix), the \(lotName) is \(costDisplay) (event rate) for \(userDesc)."
            }
        }

        // Fallback
        return "\(timePrefix), the \(lotName) is \(costDisplay) for \(userDesc)."
    }

    // MARK: - Helpers

    private static func userTypeDescription(_ userType: UserType, isVerifiedResident: Bool) -> String {
        switch userType {
        case .resident:
            return isVerifiedResident
                ? "City of San Diego residents with a verified resident account"
                : "San Diego residents"
        case .nonresident:
            return "visitors"
        case .staff:
            return "Balboa Park staff"
        case .volunteer:
            return "Balboa Park volunteers"
        case .ada:
            return "ADA placard holders"
        }
    }

    private static func extractHolidayName(_ message: String) -> String? {
        // Pattern: "Holiday (Name) – free all day"
        guard let start = message.firstIndex(of: "("),
              let end = message.firstIndex(of: ")")
        else { return nil }
        return String(message[message.index(after: start)..<end])
    }
}
