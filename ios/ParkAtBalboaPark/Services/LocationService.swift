import CoreLocation
import Foundation

// MARK: - Location Service

/// Manages the device's location using CoreLocation.
///
/// Uses the `@Observable` macro so SwiftUI views automatically update when
/// ``currentLocation`` or ``authorizationStatus`` change.
///
/// Usage:
/// ```swift
/// let location = LocationService()
/// location.requestPermission()
/// // Views observe location.currentLocation directly.
/// ```
///
/// Remember to add `NSLocationWhenInUseUsageDescription` to Info.plist.
@Observable
class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    /// The most recent device location, or `nil` if not yet determined.
    var currentLocation: CLLocation?

    /// The current Core Location authorization status.
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    // MARK: - Initialization

    override init() {
        super.init()
        manager.delegate = self
        // Hundred-meter accuracy is sufficient for parking lot proximity
        // and conserves battery compared to best-accuracy modes.
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: - Public Methods

    /// Request "When In Use" location authorization from the user.
    ///
    /// This triggers the system permission dialog if the status is `.notDetermined`.
    /// If already authorized, location updates begin automatically via the delegate.
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    /// Begin receiving location updates.
    func startUpdating() {
        manager.startUpdatingLocation()
    }

    /// Stop receiving location updates to conserve battery.
    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    /// Calculate the distance from the user's current location to a given coordinate.
    ///
    /// - Parameter coordinate: The target coordinate to measure distance to.
    /// - Returns: The distance in meters, or `nil` if the current location is unknown.
    func distanceTo(_ coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let current = currentLocation else { return nil }
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return current.distance(from: target)
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        currentLocation = locations.last
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        // Automatically start updates once the user grants permission.
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdating()
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        // Log but do not surface transient location errors to the user.
        // The system will retry automatically.
        print("LocationService: location update failed: \(error.localizedDescription)")
    }
}
