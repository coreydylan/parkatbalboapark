import CoreLocation
import Foundation

struct ParkingLot: Codable, Identifiable, Hashable, Sendable {
    /// UUID from Supabase, or slug when loaded from bundled JSON.
    let id: String
    let slug: String
    let name: String
    let displayName: String
    let address: String
    let lat: Double
    let lng: Double
    let capacity: Int?
    let hasEvCharging: Bool
    let hasAdaSpaces: Bool
    let hasTramStop: Bool
    let notes: String?
    let specialRules: [SpecialRule]?
    let createdAt: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    struct SpecialRule: Codable, Hashable, Sendable {
        let description: String
        let freeMinutes: Int
        let effectiveDate: String
        let endDate: String?
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        slug = try container.decode(String.self, forKey: .slug)
        id = (try? container.decode(String.self, forKey: .id)) ?? slug
        name = try container.decode(String.self, forKey: .name)
        displayName = try container.decode(String.self, forKey: .displayName)
        address = try container.decode(String.self, forKey: .address)
        lat = try container.decode(Double.self, forKey: .lat)
        lng = try container.decode(Double.self, forKey: .lng)
        capacity = try container.decodeIfPresent(Int.self, forKey: .capacity)
        hasEvCharging = try container.decode(Bool.self, forKey: .hasEvCharging)
        hasAdaSpaces = try container.decode(Bool.self, forKey: .hasAdaSpaces)
        hasTramStop = try container.decode(Bool.self, forKey: .hasTramStop)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        specialRules = try container.decodeIfPresent([SpecialRule].self, forKey: .specialRules)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
    }
}
