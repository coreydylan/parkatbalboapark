import Foundation

struct RecommendationResponse: Codable, Sendable {
    let recommendations: [ParkingRecommendation]
    let enforcementActive: Bool
    let queryTime: String
}
