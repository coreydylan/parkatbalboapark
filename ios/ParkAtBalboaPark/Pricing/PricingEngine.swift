import Foundation

/// Walking distance from a parking lot to a destination.
struct LotDestinationDistance: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let lotId: String
    let destinationId: String
    let walkingDistanceMeters: Double
    let walkingTimeSeconds: Double
}

// MARK: - Pricing Data & Cost Result

/// All data required to compute parking recommendations.
struct PricingData: Sendable {
    let lots: [ParkingLot]
    let tierAssignments: [LotTierAssignment]
    let pricingRules: [PricingRule]
    let enforcementPeriods: [EnforcementPeriod]
    let holidays: [Holiday]
    let distances: [LotDestinationDistance]?
    let destinationId: String?
    let tramScheduleFrequencyMinutes: Int?
}

/// The computed cost for parking at a lot, including display string and tips.
struct CostResult: Sendable {
    let costCents: Int
    let costDisplay: String
    let isFree: Bool
    var tips: [String]
}

// MARK: - Recommendation Request

/// A request for parking recommendations.
struct RecommendationRequest: Sendable {
    let userType: UserType
    let hasPass: Bool
    let destinationSlug: String?
    let queryTime: Date
    let visitHours: Double
}

// MARK: - Pricing Engine

/// Stateless pricing engine that computes parking costs and recommendations.
///
/// All functions are static and pure -- they take inputs and return outputs
/// with no side effects. The engine faithfully ports the TypeScript pricing
/// logic from `packages/shared/src/pricing/engine.ts`.
enum PricingEngine {

    /// Pacific timezone used for all date/time operations.
    static let pacificTimeZone = TimeZone(identifier: "America/Los_Angeles")!

    // MARK: - Formatting

    /// Format a cost in cents to a display string.
    ///
    /// - `0` or negative returns `"FREE"`
    /// - Whole dollar amounts return `"$X"` (no decimals)
    /// - Otherwise returns `"$X.XX"`
    static func formatCost(_ cents: Int) -> String {
        if cents <= 0 { return "FREE" }
        let dollars = Double(cents) / 100.0
        if cents % 100 == 0 {
            return "$\(Int(dollars))"
        }
        return String(format: "$%.2f", dollars)
    }

    /// Format walking time in seconds to a human-readable string.
    ///
    /// Returns `"1 min walk"` for values that round to zero or less.
    static func formatWalkTime(_ seconds: Double) -> String {
        let minutes = Int((seconds / 60.0).rounded())
        if minutes <= 0 { return "1 min walk" }
        return "\(minutes) min walk"
    }

    // MARK: - Date Helpers

    /// Format a `Date` as a `"yyyy-MM-dd"` string in Pacific time.
    ///
    /// Used for all date-string comparisons (tier assignments, enforcement
    /// periods, pricing rules, holidays, and special rules).
    private static func dateString(
        from date: Date,
        timeZone: TimeZone = TimeZone(identifier: "America/Los_Angeles")!
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

    /// Extract the month and day components from a `Date` in Pacific time.
    private static func monthAndDay(from date: Date) -> (month: Int, day: Int) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = pacificTimeZone
        let components = calendar.dateComponents([.month, .day], from: date)
        return (month: components.month!, day: components.day!)
    }

    /// Extract the day-of-week, hour, and minute from a `Date` in Pacific time.
    ///
    /// The day-of-week uses JavaScript convention: Sunday = 0 ... Saturday = 6.
    private static func timeComponents(from date: Date) -> (dayOfWeek: Int, hour: Int, minute: Int) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = pacificTimeZone
        let components = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        // Calendar.weekday: Sunday = 1 ... Saturday = 7
        // JavaScript Date.getDay(): Sunday = 0 ... Saturday = 6
        let dayOfWeek = components.weekday! - 1
        return (dayOfWeek: dayOfWeek, hour: components.hour!, minute: components.minute!)
    }

    /// Parse a time string like `"08:00"` into total minutes since midnight.
    private static func parseTimeToMinutes(_ time: String) -> Int {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        let hours = parts.count > 0 ? parts[0] : 0
        let minutes = parts.count > 1 ? parts[1] : 0
        return hours * 60 + minutes
    }

    // MARK: - Holiday Check

    /// Check whether a date falls on a holiday.
    ///
    /// Recurring holidays match by month and day regardless of year.
    /// Non-recurring holidays match by exact `"yyyy-MM-dd"` string.
    private static func isHoliday(_ date: Date, holidays: [Holiday]) -> Bool {
        let (month, day) = monthAndDay(from: date)
        let fullDateStr = dateString(from: date)

        return holidays.contains { h in
            if h.isRecurring {
                let parts = h.date.split(separator: "-").compactMap { Int($0) }
                guard parts.count >= 3 else { return false }
                let hMonth = parts[1]
                let hDay = parts[2]
                return month == hMonth && day == hDay
            }
            return h.date == fullDateStr
        }
    }

    // MARK: - Tier Lookup

    /// Get the current pricing tier for a lot based on tier assignments and date.
    ///
    /// Filters assignments by lot ID and date range, then returns the most
    /// recently effective assignment. Defaults to `.free` if none apply.
    static func getCurrentTier(
        lotId: String,
        tierAssignments: [LotTierAssignment],
        date: Date
    ) -> LotTier {
        let dateStr = dateString(from: date)

        let applicable = tierAssignments
            .filter { ta in
                ta.lotId == lotId
                    && ta.effectiveDate <= dateStr
                    && (ta.endDate == nil || ta.endDate! >= dateStr)
            }
            .sorted { $0.effectiveDate > $1.effectiveDate }

        guard let first = applicable.first else { return .free }
        return first.tier
    }

    // MARK: - Enforcement

    /// Check whether parking enforcement is active at a given time.
    ///
    /// Enforcement is inactive on holidays. Otherwise, it checks whether the
    /// time falls within any active enforcement period's day-of-week and time
    /// window.
    static func isEnforcementActive(
        time: Date,
        enforcement: [EnforcementPeriod],
        holidays: [Holiday]
    ) -> Bool {
        if isHoliday(time, holidays: holidays) { return false }

        let (dayOfWeek, hour, minute) = timeComponents(from: time)
        let currentMinutes = hour * 60 + minute
        let dateStr = dateString(from: time)

        return enforcement.contains { ep in
            if ep.effectiveDate > dateStr { return false }
            if let endDate = ep.endDate, endDate < dateStr { return false }
            if !ep.daysOfWeek.contains(dayOfWeek) { return false }

            let startMinutes = parseTimeToMinutes(ep.startTime)
            let endMinutes = parseTimeToMinutes(ep.endTime)
            return currentMinutes >= startMinutes && currentMinutes < endMinutes
        }
    }

    // MARK: - Pricing Rule Lookup

    /// Find the applicable pricing rule for a given tier, user type, and date.
    ///
    /// Filters rules by tier, user type, and date range, then returns the most
    /// recently effective rule. Returns `nil` if no rule applies.
    private static func findPricingRule(
        tier: LotTier,
        userType: UserType,
        rules: [PricingRule],
        date: Date
    ) -> PricingRule? {
        let dateStr = dateString(from: date)

        let applicable = rules
            .filter { r in
                r.tier == tier
                    && r.userType == userType
                    && r.effectiveDate <= dateStr
                    && (r.endDate == nil || r.endDate! >= dateStr)
            }
            .sorted { $0.effectiveDate > $1.effectiveDate }

        return applicable.first
    }

    // MARK: - Cost Computation

    /// Compute the parking cost for a specific lot.
    ///
    /// Applies the following rules in order:
    /// 1. Free-tier lots are always free.
    /// 2. Outside enforcement hours, parking is free.
    /// 3. Pass holders park free.
    /// 4. Staff and volunteers park free in Free, Standard, and Economy lots.
    /// 5. Lot-specific special rules (e.g. first N hours free).
    /// 6. Standard pricing rule lookup with nonresident fallback.
    static func computeLotCost(
        lot: ParkingLot,
        tier: LotTier,
        userType: UserType,
        hasPass: Bool,
        visitHours: Double,
        rules: [PricingRule],
        enforced: Bool,
        queryDate: Date
    ) -> CostResult {
        var tips: [String] = []

        // Free tier is always free
        if tier == .free {
            tips.append("This lot is always free")
            return CostResult(costCents: 0, costDisplay: "FREE", isFree: true, tips: tips)
        }

        // Not enforced means free
        if !enforced {
            tips.append("Parking is free outside enforcement hours")
            return CostResult(costCents: 0, costDisplay: "FREE", isFree: true, tips: tips)
        }

        // Pass holders park free
        if hasPass {
            tips.append("Your parking pass covers this lot")
            return CostResult(costCents: 0, costDisplay: "FREE", isFree: true, tips: tips)
        }

        // Staff and volunteers park free in tier 0, 2, 3
        if (userType == .staff || userType == .volunteer) && tier != .premium {
            tips.append("Staff and volunteers park free in Free, Standard, and Economy lots")
            return CostResult(costCents: 0, costDisplay: "FREE", isFree: true, tips: tips)
        }

        // Check lot-specific special rules (e.g. first N hours free)
        if let specialRules = lot.specialRules {
            let dateStr = dateString(from: queryDate)
            let applicableRule = specialRules.first { sr in
                sr.freeMinutes > 0
                    && sr.effectiveDate <= dateStr
                    && (sr.endDate == nil || sr.endDate! >= dateStr)
            }
            if let rule = applicableRule, visitHours <= Double(rule.freeMinutes) / 60.0 {
                tips.append(rule.description)
                return CostResult(costCents: 0, costDisplay: "FREE", isFree: true, tips: tips)
            }
        }

        // Look up the pricing rule
        if let rule = findPricingRule(tier: tier, userType: userType, rules: rules, date: queryDate) {
            return computeCostFromRule(rule, visitHours: visitHours, tips: tips)
        }

        // Fallback: try nonresident rate if no specific rate found
        if let fallbackRule = findPricingRule(tier: tier, userType: .nonresident, rules: rules, date: queryDate) {
            return computeCostFromRule(fallbackRule, visitHours: visitHours, tips: tips)
        }

        // No pricing information available
        tips.append("Pricing information unavailable")
        return CostResult(costCents: 0, costDisplay: "FREE", isFree: true, tips: tips)
    }

    /// Compute cost from a specific pricing rule.
    private static func computeCostFromRule(
        _ rule: PricingRule,
        visitHours: Double,
        tips: [String]
    ) -> CostResult {
        var tips = tips
        var costCents: Int

        switch rule.durationType {
        case .hourly:
            let hours = Int(ceil(visitHours))
            costCents = rule.rateCents * hours
            if let maxDaily = rule.maxDailyCents, costCents > maxDaily {
                costCents = maxDaily
                tips.append("Daily max of \(formatCost(maxDaily)) applied")
            }
            tips.append("\(formatCost(rule.rateCents))/hr")

        case .daily:
            costCents = rule.rateCents
            tips.append("Flat daily rate")

        case .event:
            costCents = rule.rateCents
            tips.append("Event rate applies")
        }

        return CostResult(
            costCents: costCents,
            costDisplay: formatCost(costCents),
            isFree: costCents == 0,
            tips: tips
        )
    }

    // MARK: - Ranking

    /// Rank recommendations by weighted score.
    ///
    /// Normalizes cost and walking distance to a 0-1 range and applies the
    /// following weights:
    /// - Cost: 40%
    /// - Walking distance: 35%
    /// - Tram access: 10%
    /// - Tier preference: 10%
    /// - ADA baseline: 5%
    ///
    /// Returns recommendations sorted by score descending (best first).
    static func rankRecommendations(
        _ recs: [ParkingRecommendation]
    ) -> [ParkingRecommendation] {
        if recs.isEmpty { return [] }

        let costWeight = 0.4
        let walkWeight = 0.35
        let tramWeight = 0.1
        let tierWeight = 0.1
        let adaWeight = 0.05

        // Find max values for normalization (minimum of 1 to avoid division by zero)
        let maxCost = Double(max(recs.map(\.costCents).max() ?? 1, 1))
        let maxWalk = max(recs.compactMap(\.walkingDistanceMeters).max() ?? 1.0, 1.0)

        let scored: [ParkingRecommendation] = recs.map { rec in
            let costNorm = Double(rec.costCents) / maxCost
            let walkNorm = (rec.walkingDistanceMeters ?? maxWalk) / maxWalk
            let tramBonus: Double = rec.hasTram ? 1.0 : 0.0
            let tierNorm = Double(rec.tier.rawValue) / 3.0

            let rawScore =
                costWeight * (1.0 - costNorm)
                + walkWeight * (1.0 - walkNorm)
                + tramWeight * tramBonus
                + tierWeight * (1.0 - tierNorm)
                + adaWeight

            let score = (rawScore * 1000.0).rounded() / 1000.0

            return ParkingRecommendation(
                lotSlug: rec.lotSlug,
                lotName: rec.lotName,
                lotDisplayName: rec.lotDisplayName,
                lat: rec.lat,
                lng: rec.lng,
                tier: rec.tier,
                costCents: rec.costCents,
                costDisplay: rec.costDisplay,
                isFree: rec.isFree,
                walkingDistanceMeters: rec.walkingDistanceMeters,
                walkingTimeSeconds: rec.walkingTimeSeconds,
                walkingTimeDisplay: rec.walkingTimeDisplay,
                hasTram: rec.hasTram,
                tramTimeMinutes: rec.tramTimeMinutes,
                score: score,
                tips: rec.tips
            )
        }

        return scored.sorted { $0.score > $1.score }
    }

    // MARK: - Full Recommendation Pipeline

    /// Compute parking recommendations for all lots given a request and pricing data.
    ///
    /// This is the main entry point that mirrors `computeRecommendations()` in the
    /// TypeScript engine. It:
    /// 1. Determines if enforcement is active at the query time.
    /// 2. Computes cost for each lot based on tier, user type, and rules.
    /// 3. Attaches walking distance and tram information when available.
    /// 4. Ranks results by weighted score and returns them sorted best-first.
    static func computeRecommendations(
        request: RecommendationRequest,
        data: PricingData
    ) -> [ParkingRecommendation] {
        let queryTime = request.queryTime

        let enforced = isEnforcementActive(
            time: queryTime,
            enforcement: data.enforcementPeriods,
            holidays: data.holidays
        )

        let recommendations: [ParkingRecommendation] = data.lots.map { lot in
            let tier = getCurrentTier(
                lotId: lot.id,
                tierAssignments: data.tierAssignments,
                date: queryTime
            )

            var costResult = computeLotCost(
                lot: lot,
                tier: tier,
                userType: request.userType,
                hasPass: request.hasPass,
                visitHours: request.visitHours,
                rules: data.pricingRules,
                enforced: enforced,
                queryDate: queryTime
            )

            // Find walking distance to requested destination
            var walkingDistanceMeters: Double?
            var walkingTimeSeconds: Double?
            var walkingTimeDisplay: String?

            if let distances = data.distances, request.destinationSlug != nil {
                let distance = distances.first { d in
                    d.lotId == lot.id
                        && (data.destinationId == nil || d.destinationId == data.destinationId)
                }
                if let distance {
                    walkingDistanceMeters = distance.walkingDistanceMeters
                    walkingTimeSeconds = distance.walkingTimeSeconds
                    walkingTimeDisplay = formatWalkTime(distance.walkingTimeSeconds)
                }
            }

            // Tram info: compute estimated wait as (frequency / 2) + 5 min ride,
            // falling back to 5 min default when schedule data is unavailable
            let hasTram = lot.hasTramStop
            let tramTimeMinutes: Int? = hasTram
                ? (data.tramScheduleFrequencyMinutes.map { Int(($0 / 2) + 5) } ?? 5)
                : nil

            // Add contextual tips
            if lot.hasEvCharging {
                costResult.tips.append("EV charging available")
            }
            if lot.hasAdaSpaces {
                costResult.tips.append("ADA accessible spaces available")
            }
            if hasTram {
                costResult.tips.append("Free tram stop at this lot")
            }

            return ParkingRecommendation(
                lotSlug: lot.slug,
                lotName: lot.name,
                lotDisplayName: lot.displayName,
                lat: lot.lat,
                lng: lot.lng,
                tier: tier,
                costCents: costResult.costCents,
                costDisplay: costResult.costDisplay,
                isFree: costResult.isFree,
                walkingDistanceMeters: walkingDistanceMeters,
                walkingTimeSeconds: walkingTimeSeconds,
                walkingTimeDisplay: walkingTimeDisplay,
                hasTram: hasTram,
                tramTimeMinutes: tramTimeMinutes,
                score: 0,
                tips: costResult.tips
            )
        }

        return rankRecommendations(recommendations)
    }
}
