import SwiftUI
import MapKit

struct ParkMapView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var state = state

        Map(position: $state.cameraPosition, interactionModes: .all) {
            // User location
            UserAnnotation()

            // Parking lot annotations
            ForEach(lotAnnotations) { annotation in
                Annotation(annotation.displayName, coordinate: annotation.coordinate) {
                    LotMarkerView(
                        label: "P",
                        costColor: annotation.costColor,
                        isSelected: state.selectedLot?.lotSlug == annotation.lotSlug,
                        hasTram: annotation.hasTram
                    )
                    .onTapGesture {
                        if let rec = state.recommendations.first(where: { $0.lotSlug == annotation.lotSlug }) {
                            state.selectLot(rec)
                        }
                    }
                }
                .annotationTitles(.hidden)
            }

            // Destination pin
            if let dest = state.selectedDestination {
                Annotation(dest.displayName, coordinate: dest.coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundStyle(.red)
                        .background(Circle().fill(.white).frame(width: 20, height: 20))
                }
            }

            // Walking route (blue dashed line from selected lot to destination)
            if let selectedLot = state.selectedLot,
               let dest = state.selectedDestination {
                MapPolyline(coordinates: [selectedLot.coordinate, dest.coordinate])
                    .stroke(.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 4]))
            }

            // Tram route (orange dashed)
            if state.mapFilters.showTram, let tramData = state.tramData {
                let tramCoords = tramData.stops.sorted(by: { $0.stopOrder < $1.stopOrder }).map(\.coordinate)
                if tramCoords.count >= 2 {
                    // Close the loop
                    MapPolyline(coordinates: tramCoords + [tramCoords[0]])
                        .stroke(.orange, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [5, 3]))

                    // Tram stop markers
                    ForEach(tramData.stops) { stop in
                        Annotation(stop.name, coordinate: stop.coordinate) {
                            Circle()
                                .fill(.orange)
                                .frame(width: 12, height: 12)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                        }
                    }
                }
            }

            // Waypoint annotations would go here based on mapFilters
            // (restrooms, water, ev charging)
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .including([.park])))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
    }

    // MARK: - Computed

    /// Build annotation data from recommendations (if available) or from lots.
    private var lotAnnotations: [LotAnnotation] {
        if state.recommendations.isEmpty {
            // Show lots with default styling when no recommendations yet
            return state.lots.map { lot in
                LotAnnotation(
                    lotSlug: lot.slug,
                    displayName: lot.displayName,
                    coordinate: lot.coordinate,
                    costColor: .gray,
                    hasTram: lot.hasTramStop
                )
            }
        } else {
            return state.recommendations.map { rec in
                LotAnnotation(
                    lotSlug: rec.lotSlug,
                    displayName: rec.lotDisplayName,
                    coordinate: rec.coordinate,
                    costColor: rec.costColor,
                    hasTram: rec.hasTram
                )
            }
        }
    }
}

// MARK: - Supporting Types

struct LotAnnotation: Identifiable {
    let lotSlug: String
    let displayName: String
    let coordinate: CLLocationCoordinate2D
    let costColor: Color
    let hasTram: Bool

    var id: String { lotSlug }
}
