import Foundation

struct Holiday: Codable, Identifiable, Hashable, Sendable {
    let name: String
    let date: String
    let isRecurring: Bool

    var id: String { "\(name)-\(date)" }
}
