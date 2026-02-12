import MapKit
import SwiftUI

struct ParkMapView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var mapState = state.map

        Map(position: $mapState.cameraPosition, interactionModes: .all) {
            UserAnnotation()

            ForEach(state.parking.lotAnnotations) { annotation in
                Annotation(annotation.displayName, coordinate: annotation.coordinate) {
                    LotMarkerView(
                        label: "P",
                        tier: annotation.tier,
                        costColor: annotation.costColor,
                        isSelected: state.parking.selectedLot?.lotSlug == annotation.lotSlug,
                        hasTram: annotation.hasTram
                    )
                    .onTapGesture {
                        if let rec = state.parking.recommendations.first(where: {
                            $0.lotSlug == annotation.lotSlug
                        }) {
                            state.selectLot(rec)
                        }
                    }
                }
                .annotationTitles(.hidden)
            }

            if let dest = state.parking.selectedDestination {
                Annotation(dest.displayName, coordinate: dest.coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundStyle(.red)
                        .background(Circle().fill(.white).frame(width: 20, height: 20))
                }
            }

            if let selectedLot = state.parking.selectedLot {
                if let routeCoords = state.parking.walkingRoutes[selectedLot.lotSlug],
                    routeCoords.count >= 2
                {
                    // Real walking route from MapKit
                    MapPolyline(coordinates: routeCoords)
                        .stroke(
                            Color.accentColor,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                } else if let dest = state.parking.selectedDestination {
                    // Fallback dashed line while route loads
                    MapPolyline(coordinates: [selectedLot.coordinate, dest.coordinate])
                        .stroke(
                            Color.accentColor.opacity(0.5),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 4]))
                }
            }

            if state.map.filters.showStreetMeters {
                ForEach(state.parking.streetSegments) { segment in
                    Annotation(segment.streetName, coordinate: segment.coordinate) {
                        StreetMeterMarkerView(
                            meterCount: segment.meterCount,
                            markerColor: segment.markerColor
                        )
                    }
                    .annotationTitles(.hidden)
                }
            }

            if state.map.filters.showTram, let tramData = state.parking.tramData {
                let tramCoords = tramData.stops.sorted(by: { $0.stopOrder < $1.stopOrder }).map(
                    \.coordinate)
                if tramCoords.count >= 2 {
                    MapPolyline(coordinates: tramCoords + [tramCoords[0]])
                        .stroke(
                            Color.tram,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [5, 3]))

                    ForEach(tramData.stops) { stop in
                        Annotation(stop.name, coordinate: stop.coordinate) {
                            Circle()
                                .fill(Color.tram)
                                .frame(width: 12, height: 12)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                        }
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .including([.park])))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .overlay(alignment: .top) {
            MapFilterBar()
                .padding(.top, 8)
        }
        .onChange(of: state.map.filters.showStreetMeters) {
            if state.map.filters.showStreetMeters {
                Task { await state.parking.fetchStreetSegments() }
            }
        }
    }
}

// MARK: - Supporting Types

struct LotAnnotation: Identifiable {
    let lotSlug: String
    let displayName: String
    let coordinate: CLLocationCoordinate2D
    let tier: LotTier?
    let costColor: Color
    let hasTram: Bool

    var id: String { lotSlug }
}
