import CoreLocation
import Foundation

struct TramStop: Codable, Identifiable, Hashable, Sendable {
    let name: String
    let lotSlug: String?
    let lat: Double
    let lng: Double
    let stopOrder: Int

    var id: String { name }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

struct TramSchedule: Codable, Hashable, Sendable {
    let startTime: String
    let endTime: String
    let frequencyMinutes: Int
    let daysOfWeek: [Int]
    let effectiveDate: String
    let endDate: String?
}

struct TramData: Codable, Sendable {
    let stops: [TramStop]
    let schedule: TramSchedule
    let notes: String
}
