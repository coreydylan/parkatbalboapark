import MapKit
import OSLog
import UIKit

private let logger = Logger(subsystem: "com.parkatbalboapark.app", category: "LookAroundService")

/// Fetches Apple Look Around scenes and lightweight snapshots for parking lot coordinates.
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

    /// Capture a static snapshot image from a Look Around scene.
    /// Much lighter than an interactive LookAroundPreview — suitable for use in scrolling lists.
    static func fetchSnapshot(scene: MKLookAroundScene, size: CGSize) async -> UIImage? {
        let options = MKLookAroundSnapshotter.Options()
        options.size = size
        let snapshotter = MKLookAroundSnapshotter(scene: scene, options: options)

        do {
            let snapshot = try await snapshotter.snapshot
            return snapshot.image
        } catch {
            logger.info("Failed to snapshot Look Around scene: \(error.localizedDescription)")
            return nil
        }
    }
}
