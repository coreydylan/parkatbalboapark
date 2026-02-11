import CoreLocation
import SwiftUI

struct ParkingRecommendation: Codable, Identifiable, Hashable, Sendable {
    let lotSlug: String
    let lotName: String
    let lotDisplayName: String
    let lat: Double
    let lng: Double
    let tier: LotTier
    let costCents: Int
    let costDisplay: String
    let isFree: Bool
    let walkingDistanceMeters: Double?
    let walkingTimeSeconds: Double?
    let walkingTimeDisplay: String?
    let hasTram: Bool
    let tramTimeMinutes: Int?
    let score: Double
    let tips: [String]

    var id: String { lotSlug }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var costColor: Color {
        if isFree {
            return .green
        } else if costCents <= 800 {
            return .orange
        } else {
            return .red
        }
    }
}
