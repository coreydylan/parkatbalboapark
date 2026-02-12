import CoreLocation
import Foundation
import SwiftUI

// MARK: - Destination Area

enum DestinationArea: String, Codable, CaseIterable, Hashable, Sendable {
    case centralMesa = "central_mesa"
    case palisades
    case eastMesa = "east_mesa"
    case floridaCanyon = "florida_canyon"
    case morleyField = "morley_field"
    case panAmerican = "pan_american"

    var displayName: String {
        switch self {
        case .centralMesa: "Central Mesa"
        case .palisades: "Palisades"
        case .eastMesa: "East Mesa"
        case .floridaCanyon: "Florida Canyon"
        case .morleyField: "Morley Field"
        case .panAmerican: "Pan American"
        }
    }
}

// MARK: - Destination Type

enum DestinationType: String, Codable, CaseIterable, Hashable, Sendable {
    case museum
    case garden
    case theater
    case landmark
    case recreation
    case dining
    case zoo
    case other

    /// SF Symbol name for this destination type.
    var icon: String {
        switch self {
        case .museum: "building.columns"
        case .garden: "leaf"
        case .theater: "theatermasks"
        case .landmark: "mappin"
        case .recreation: "figure.run"
        case .dining: "fork.knife"
        case .zoo: "tortoise"
        case .other: "ellipsis"
        }
    }

    /// Brand color for this destination type, used for card tinting and pill accents.
    var color: Color {
        switch self {
        case .museum: Color(.sRGB, red: 0.85, green: 0.55, blue: 0.2)   // warm amber
        case .garden: Color(.sRGB, red: 0.2, green: 0.65, blue: 0.35)   // forest green
        case .theater: Color(.sRGB, red: 0.55, green: 0.3, blue: 0.75)  // purple
        case .landmark: Color(.sRGB, red: 0.25, green: 0.5, blue: 0.85) // blue
        case .recreation: Color(.sRGB, red: 0.9, green: 0.5, blue: 0.15) // orange
        case .dining: Color(.sRGB, red: 0.85, green: 0.25, blue: 0.25)  // red
        case .zoo: Color(.sRGB, red: 0.2, green: 0.65, blue: 0.65)      // teal
        case .other: Color(.sRGB, red: 0.5, green: 0.5, blue: 0.55)     // gray
        }
    }
}

// MARK: - Destination

struct Destination: Codable, Identifiable, Hashable, Sendable {
    /// UUID from Supabase, or slug when loaded from bundled JSON.
    let id: String
    let slug: String
    let name: String
    let displayName: String
    let area: DestinationArea
    let type: DestinationType
    let address: String?
    let lat: Double
    let lng: Double
    let websiteUrl: String?
    let hours: String?
    let createdAt: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    /// Memberwise initializer for creating synthetic destinations (e.g. from MapKit POI results).
    init(
        id: String,
        slug: String,
        name: String,
        displayName: String,
        area: DestinationArea,
        type: DestinationType,
        address: String?,
        lat: Double,
        lng: Double,
        websiteUrl: String? = nil,
        hours: String? = nil,
        createdAt: String? = nil
    ) {
        self.id = id
        self.slug = slug
        self.name = name
        self.displayName = displayName
        self.area = area
        self.type = type
        self.address = address
        self.lat = lat
        self.lng = lng
        self.websiteUrl = websiteUrl
        self.hours = hours
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        slug = try container.decode(String.self, forKey: .slug)
        id = (try? container.decode(String.self, forKey: .id)) ?? slug
        name = try container.decode(String.self, forKey: .name)
        displayName = try container.decode(String.self, forKey: .displayName)
        area = try container.decode(DestinationArea.self, forKey: .area)
        type = try container.decode(DestinationType.self, forKey: .type)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        lat = try container.decode(Double.self, forKey: .lat)
        lng = try container.decode(Double.self, forKey: .lng)
        websiteUrl = try container.decodeIfPresent(String.self, forKey: .websiteUrl)
        hours = try container.decodeIfPresent(String.self, forKey: .hours)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
    }
}
