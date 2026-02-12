import CoreLocation

@MainActor @Observable
class LocationService {
    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private var updateTask: Task<Void, Never>?
    private let manager = CLLocationManager()

    init() {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse
            || authorizationStatus == .authorizedAlways
        {
            startUpdating()
        }
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
        startUpdating()
    }

    func startUpdating() {
        guard updateTask == nil else { return }
        updateTask = Task {
            do {
                for try await update in CLLocationUpdate.liveUpdates(.default) {
                    if let location = update.location {
                        self.currentLocation = location
                    }
                    self.authorizationStatus = self.manager.authorizationStatus
                }
            } catch {
                // Location updates ended
            }
        }
    }

    func stopUpdating() {
        updateTask?.cancel()
        updateTask = nil
    }

    func distanceTo(_ coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let current = currentLocation else { return nil }
        return current.distance(
            from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }
}
