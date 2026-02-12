import MapKit
import SwiftUI

@MainActor @Observable
class MapState {
    var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 32.7341, longitude: -117.1446),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        ))

    var filters: MapFilters = MapFilters()

    private var rotationTimer: Timer?
    private var rotationHeading: Double = 0

    // Two-phase flyover state
    private var phase1Center: CLLocationCoordinate2D?
    private var phase2Center: CLLocationCoordinate2D?
    private var phase1Distance: Double = 400
    private var phase2Distance: Double = 600
    private var flyoverStartTime: Date?
    private let closeOrbitDuration: TimeInterval = 3.5
    private let zoomOutDuration: TimeInterval = 2.5

    func focusOn(_ coordinate: CLLocationCoordinate2D) {
        withAnimation(.smooth) {
            cameraPosition = .camera(MapCamera(
                centerCoordinate: coordinate,
                distance: 800
            ))
        }
    }

    /// Two-phase flyover: first orbits close around the lot, then zooms out to show the walking route.
    func startFlyover(
        lotCoordinate: CLLocationCoordinate2D,
        destinationCoordinate: CLLocationCoordinate2D?
    ) {
        stopFlyover()

        phase1Center = lotCoordinate
        phase1Distance = 400
        rotationHeading = 0
        flyoverStartTime = Date()

        // Calculate phase 2 target (midpoint between lot and destination)
        if let dest = destinationCoordinate {
            phase2Center = CLLocationCoordinate2D(
                latitude: (lotCoordinate.latitude + dest.latitude) / 2,
                longitude: (lotCoordinate.longitude + dest.longitude) / 2
            )
            let latDiff = abs(lotCoordinate.latitude - dest.latitude)
            let lngDiff = abs(lotCoordinate.longitude - dest.longitude)
            let spanDegrees = max(latDiff, lngDiff)
            phase2Distance = max(600, min(2000, spanDegrees * 111_000 * 1.5))
        } else {
            phase2Center = nil
        }

        // Initial tilt into 3D close orbit
        withAnimation(.easeInOut(duration: 1.2)) {
            cameraPosition = .camera(MapCamera(
                centerCoordinate: lotCoordinate,
                distance: 400,
                heading: 0,
                pitch: 60
            ))
        }

        // Start rotation
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickRotation()
            }
        }
    }

    /// Exit flyover mode and return to standard overhead view.
    func stopFlyover() {
        rotationTimer?.invalidate()
        rotationTimer = nil
        phase1Center = nil
        phase2Center = nil
        flyoverStartTime = nil
    }

    private func tickRotation() {
        guard let center1 = phase1Center, let startTime = flyoverStartTime else { return }

        let elapsed = Date().timeIntervalSince(startTime)

        let currentCenter: CLLocationCoordinate2D
        let currentDistance: Double
        let currentPitch: Double

        if elapsed < closeOrbitDuration {
            // Phase 1: close orbit around the parking lot
            currentCenter = center1
            currentDistance = phase1Distance
            currentPitch = 60
        } else if let center2 = phase2Center {
            // Phase 2: smoothly zoom out to show lot + destination
            let t = min(1.0, (elapsed - closeOrbitDuration) / zoomOutDuration)
            let eased = t * t * (3 - 2 * t) // smoothStep easing

            currentCenter = CLLocationCoordinate2D(
                latitude: center1.latitude + (center2.latitude - center1.latitude) * eased,
                longitude: center1.longitude + (center2.longitude - center1.longitude) * eased
            )
            currentDistance = phase1Distance + (phase2Distance - phase1Distance) * eased
            currentPitch = 60 + (50 - 60) * eased
        } else {
            // No destination: continue close orbit
            currentCenter = center1
            currentDistance = phase1Distance
            currentPitch = 60
        }

        rotationHeading += 0.15
        if rotationHeading >= 360 { rotationHeading -= 360 }

        cameraPosition = .camera(MapCamera(
            centerCoordinate: currentCenter,
            distance: currentDistance,
            heading: rotationHeading,
            pitch: currentPitch
        ))
    }
}

struct MapFilters {
    var showTram: Bool = false
    var showRestrooms: Bool = false
    var showWater: Bool = false
    var showEvCharging: Bool = false
    var showStreetMeters: Bool = false
}
