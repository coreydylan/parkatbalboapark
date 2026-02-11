import Foundation

struct EnforcementStatus: Codable, Sendable {
    let active: Bool
    let startTime: String?
    let endTime: String?
    let nextHoliday: NextHoliday?

    struct NextHoliday: Codable, Sendable {
        let name: String
        let date: String
    }
}
