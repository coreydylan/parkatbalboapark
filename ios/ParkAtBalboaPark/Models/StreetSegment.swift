import CoreLocation
import Foundation

struct StreetSegment: Codable, Identifiable, Hashable, Sendable {
    let segmentId: String
    let zone: String
    let area: String
    let subArea: String
    let lat: Double
    let lng: Double
    let meterCount: Int
    let rateCentsPerHour: Int
    let rateDisplay: String
    let timeStart: String?
    let timeEnd: String?
    let timeLimit: String?
    let daysInOperation: String?
    let hasMobilePay: Bool

    var id: String { segmentId }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var streetName: String {
        subArea != "Unknown" ? subArea : area
    }

    var subtitle: String? {
        zone != streetName ? zone : nil
    }

    var hoursDisplay: String? {
        guard let start = timeStart, let end = timeEnd else { return nil }
        return "\(start) – \(end)"
    }

    var markerColor: MarkerColor {
        switch rateCentsPerHour {
        case 0: .free
        case 1..<200: .cheap
        case 200..<400: .moderate
        default: .expensive
        }
    }

    enum MarkerColor {
        case free, cheap, moderate, expensive
    }
}
