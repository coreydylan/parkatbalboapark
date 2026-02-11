import Foundation

struct EnforcementPeriod: Codable, Hashable, Sendable {
    let startTime: String
    let endTime: String
    let daysOfWeek: [Int]
    let effectiveDate: String
    let endDate: String?
}
