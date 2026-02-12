import Foundation

/// Computed cost for parking at a street meter segment for a given visit window.
struct MeterCostResult: Hashable, Sendable {
    let costCents: Int
    let costDisplay: String
    let isFree: Bool
    let tips: [String]
    let exceedsTimeLimit: Bool
    let timeLimitDisplay: String?

    /// Compute the cost of parking at a meter segment for a visit.
    static func compute(
        segment: StreetSegment,
        enforcedHours: Double,
        visitDurationMinutes: Int,
        isHoliday: Bool
    ) -> MeterCostResult {
        var tips: [String] = []

        // Parse time limit (e.g. "2 HR" → 120 min, "30 MIN" → 30 min)
        let timeLimitMinutes = parseTimeLimit(segment.timeLimit)
        let timeLimitDisplay = segment.timeLimit
        let exceedsTimeLimit = timeLimitMinutes.map { visitDurationMinutes > $0 } ?? false

        if exceedsTimeLimit {
            tips.append("Visit exceeds \(segment.timeLimit ?? "") time limit")
        }

        // Free when outside enforcement or on holidays
        if isHoliday {
            tips.append("Holiday – free parking")
            return MeterCostResult(
                costCents: 0, costDisplay: "FREE", isFree: true,
                tips: tips, exceedsTimeLimit: exceedsTimeLimit,
                timeLimitDisplay: timeLimitDisplay
            )
        }

        if enforcedHours <= 0 {
            tips.append("Outside enforcement hours – free parking")
            return MeterCostResult(
                costCents: 0, costDisplay: "FREE", isFree: true,
                tips: tips, exceedsTimeLimit: exceedsTimeLimit,
                timeLimitDisplay: timeLimitDisplay
            )
        }

        // Compute cost: rate per hour × enforced hours (rounded up to nearest hour)
        let enforcedHoursCeil = Int(ceil(enforcedHours))
        let costCents = segment.rateCentsPerHour * enforcedHoursCeil

        if segment.hasMobilePay {
            tips.append("Mobile pay available")
        }

        if let hours = segment.hoursDisplay {
            tips.append("Meters active \(hours)")
        }

        return MeterCostResult(
            costCents: costCents,
            costDisplay: PricingEngine.formatCost(costCents),
            isFree: costCents == 0,
            tips: tips,
            exceedsTimeLimit: exceedsTimeLimit,
            timeLimitDisplay: timeLimitDisplay
        )
    }

    /// Parse time limit strings like "2 HR", "30 MIN", "4 HOUR" into minutes.
    private static func parseTimeLimit(_ limit: String?) -> Int? {
        guard let limit = limit?.uppercased().trimmingCharacters(in: .whitespaces),
              !limit.isEmpty else { return nil }

        // Extract leading number
        let digits = limit.prefix(while: { $0.isNumber })
        guard let value = Int(digits) else { return nil }

        if limit.contains("HR") || limit.contains("HOUR") {
            return value * 60
        }
        if limit.contains("MIN") {
            return value
        }

        return nil
    }
}
