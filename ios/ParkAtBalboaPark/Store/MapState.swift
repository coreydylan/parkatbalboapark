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

    // Two-phase flyover state
    private var phase1Center: CLLocationCoordinate2D?
    private var phase2Center: CLLocationCoordinate2D?
    private var phase1Distance: Double = 400
    private var phase2Distance: Double = 600
    private let closeOrbitDuration: TimeInterval = 3.5
    private let zoomOutDuration: TimeInterval = 2.5
    private let orbitPeriod: TimeInterval = 20 // seconds for one full 360° rotation

    private var phaseTransitionTask: Task<Void, Never>?

    func fitRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        let midLat = (origin.latitude + destination.latitude) / 2
        let midLng = (origin.longitude + destination.longitude) / 2
        let latDelta = abs(origin.latitude - destination.latitude) * 1.6
        let lngDelta = abs(origin.longitude - destination.longitude) * 1.6
        let span = MKCoordinateSpan(
            latitudeDelta: max(latDelta, 0.005),
            longitudeDelta: max(lngDelta, 0.005)
        )
        withAnimation(.smooth(duration: 0.6)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: midLat, longitude: midLng),
                span: span
            ))
        }
    }

    func focusOn(_ coordinate: CLLocationCoordinate2D) {
        withAnimation(.smooth) {
            cameraPosition = .camera(MapCamera(
                centerCoordinate: coordinate,
                distance: 800
            ))
        }
    }

    /// Two-phase flyover: first orbits close around the lot, then zooms out to show the walking route.
    /// Phase 1 uses a single long-duration linear animation for the orbit (MapKit interpolates on GPU).
    /// Phase 2 transitions camera to a wider view after `closeOrbitDuration` seconds.
    func startFlyover(
        lotCoordinate: CLLocationCoordinate2D,
        destinationCoordinate: CLLocationCoordinate2D?
    ) {
        stopFlyover()

        phase1Center = lotCoordinate
        phase1Distance = 400

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

        // Initial tilt into 3D close orbit (no rotation yet)
        withAnimation(.easeInOut(duration: 1.2)) {
            cameraPosition = .camera(MapCamera(
                centerCoordinate: lotCoordinate,
                distance: 400,
                heading: 0,
                pitch: 60
            ))
        }

        // After the tilt animation settles, start the continuous orbit via a single long animation.
        // MapKit smoothly interpolates heading from 0→360 on the GPU — no per-frame Timer needed.
        phaseTransitionTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled, let self else { return }

            // Phase 1: continuous orbit — single linear animation for full rotation
            withAnimation(.linear(duration: self.orbitPeriod).repeatForever(autoreverses: false)) {
                self.cameraPosition = .camera(MapCamera(
                    centerCoordinate: lotCoordinate,
                    distance: 400,
                    heading: 360,
                    pitch: 60
                ))
            }

            // Wait for the close orbit duration before transitioning
            try? await Task.sleep(for: .seconds(self.closeOrbitDuration))
            guard !Task.isCancelled else { return }

            // Phase 2: zoom out to show lot + destination (if available)
            if let center2 = self.phase2Center {
                withAnimation(.easeInOut(duration: self.zoomOutDuration)) {
                    self.cameraPosition = .camera(MapCamera(
                        centerCoordinate: center2,
                        distance: self.phase2Distance,
                        heading: 360,
                        pitch: 50
                    ))
                }
            }
        }
    }

    /// Exit flyover mode and return to standard overhead view.
    func stopFlyover() {
        phaseTransitionTask?.cancel()
        phaseTransitionTask = nil
        phase1Center = nil
        phase2Center = nil
    }
}

struct MapFilters {
    var showTram: Bool = false
    var showRestrooms: Bool = false
    var showWater: Bool = false
    var showEvCharging: Bool = false
    var showStreetMeters: Bool = false
}
