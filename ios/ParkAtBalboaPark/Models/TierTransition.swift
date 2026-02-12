import Foundation

/// Represents a tier change for a parking lot, derived from tier history entries.
struct TierTransition: Identifiable, Hashable, Sendable {
    let id: String
    let fromTier: LotTier
    let toTier: LotTier
    let date: Date
    let dateString: String
    let isFuture: Bool

    /// Build tier transitions from a lot's tier history.
    static func from(tierHistory: [ParkingLot.TierHistoryEntry]) -> [TierTransition] {
        let sorted = tierHistory.sorted { $0.effectiveDate < $1.effectiveDate }
        guard sorted.count > 1 else { return [] }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "America/Los_Angeles")

        let now = Date()
        var transitions: [TierTransition] = []

        for i in 1..<sorted.count {
            let prev = sorted[i - 1]
            let curr = sorted[i]
            guard let fromTier = LotTier(rawValue: prev.tier),
                  let toTier = LotTier(rawValue: curr.tier),
                  let date = formatter.date(from: curr.effectiveDate)
            else { continue }

            transitions.append(TierTransition(
                id: "\(curr.effectiveDate)-\(curr.tier)",
                fromTier: fromTier,
                toTier: toTier,
                date: date,
                dateString: curr.effectiveDate,
                isFuture: date > now
            ))
        }

        return transitions
    }
}
