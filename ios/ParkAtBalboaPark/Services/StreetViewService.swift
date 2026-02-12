import MapKit
import OSLog

private let logger = Logger(subsystem: "com.parkatbalboapark.app", category: "LookAroundService")

/// Fetches Apple Look Around scenes for parking lot coordinates.
enum LookAroundService {

    /// Fetch a Look Around scene for the given coordinates, or nil if unavailable.
    static func fetchScene(lat: Double, lng: Double) async -> MKLookAroundScene? {
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        let request = MKLookAroundSceneRequest(coordinate: coordinate)

        do {
            return try await request.scene
        } catch {
            logger.info("No Look Around imagery at \(lat), \(lng): \(error.localizedDescription)")
            return nil
        }
    }
}
