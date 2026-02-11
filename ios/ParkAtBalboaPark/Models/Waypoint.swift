import CoreLocation
import SwiftUI

enum WaypointCategory: String, Codable, CaseIterable, Hashable, Sendable {
    case drinkingWater = "amenity_drinking_water"
    case restroom = "amenity_restroom"
    case evCharging = "amenity_ev_charging"

    var label: String {
        switch self {
        case .drinkingWater: "Water"
        case .restroom: "Restrooms"
        case .evCharging: "EV Charging"
        }
    }

    /// SF Symbol name for this waypoint category.
    var icon: String {
        switch self {
        case .drinkingWater: "drop.fill"
        case .restroom: "toilet"
        case .evCharging: "ev.plug.ac.type.2"
        }
    }

    var color: Color {
        switch self {
        case .drinkingWater: .cyan
        case .restroom: .blue
        case .evCharging: .green
        }
    }
}

struct Waypoint: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String?
    let category: WaypointCategory
    let lat: Double
    let lng: Double
    let onOfficialMap: Bool

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}
