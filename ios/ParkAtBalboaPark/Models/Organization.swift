import Foundation

struct Organization: Codable, Identifiable, Hashable {
    let id: String
    let slug: String
    let name: String
    let category: String

    var categoryLabel: String {
        switch category {
        case "museum": "Museum"
        case "performing-arts": "Performing Arts"
        case "cultural": "Cultural Center"
        case "garden": "Garden"
        case "nonprofit": "Nonprofit"
        case "club": "Club"
        case "zoo": "Zoo"
        case "government": "Government"
        default: category.capitalized
        }
    }
}
