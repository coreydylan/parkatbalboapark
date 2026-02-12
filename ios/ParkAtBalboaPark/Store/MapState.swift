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

    func focusOn(_ coordinate: CLLocationCoordinate2D) {
        withAnimation(.smooth) {
            cameraPosition = .camera(MapCamera(
                centerCoordinate: coordinate,
                distance: 800
            ))
        }
    }
}

struct MapFilters {
    var showTram: Bool = false
    var showRestrooms: Bool = false
    var showWater: Bool = false
    var showEvCharging: Bool = false
}
