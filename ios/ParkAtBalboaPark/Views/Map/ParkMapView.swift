import MapKit
import SwiftUI

struct ParkMapView: View {
    @Environment(AppState.self) private var state
    @State private var currentSpan = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)

    private var filteredMeterSegments: [StreetSegment] {
        let latDelta = currentSpan.latitudeDelta
        return state.parking.streetSegments.filter { seg in
            if latDelta < 0.005 { return true }
            if latDelta < 0.01 { return seg.meterCount >= 5 }
            if latDelta < 0.02 { return seg.meterCount >= 10 }
            return seg.meterCount >= 20
        }
    }

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
                        isSelected: {
                            if case .lot(let rec) = state.parking.selectedOption {
                                return rec.lotSlug == annotation.lotSlug
                            }
                            return false
                        }(),
                        hasTram: annotation.hasTram
                    )
                    .onTapGesture {
                        if let rec = state.parking.recommendations.first(where: {
                            $0.lotSlug == annotation.lotSlug
                        }) {
                            state.selectOption(.lot(rec))
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

            if let selectedOption = state.parking.selectedOption {
                let routeKey = state.parking.walkingRouteKey(for: selectedOption)
                if let routeCoords = state.parking.walkingRoutes[routeKey],
                    routeCoords.count >= 2
                {
                    // Real walking route from MapKit
                    MapPolyline(coordinates: routeCoords)
                        .stroke(
                            Color.accentColor,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                } else if let dest = state.parking.selectedDestination {
                    // Fallback dashed line while route loads
                    MapPolyline(coordinates: [selectedOption.coordinate, dest.coordinate])
                        .stroke(
                            Color.accentColor.opacity(0.5),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 4]))
                }
            }

            if state.map.filters.showStreetMeters || state.parking.showMeters {
                ForEach(filteredMeterSegments) { segment in
                    Annotation(segment.streetName, coordinate: segment.coordinate) {
                        StreetMeterMarkerView(
                            meterCount: segment.meterCount,
                            markerColor: segment.markerColor,
                            isSelected: {
                                if case .meter(let seg, _) = state.parking.selectedOption {
                                    return seg.segmentId == segment.segmentId
                                }
                                return false
                            }()
                        )
                        .onTapGesture {
                            let cost = MeterCostResult.compute(
                                segment: segment,
                                enforcedHours: state.parking.enforcedVisitHours,
                                visitDurationMinutes: state.parking.visitDurationMinutes,
                                isHoliday: ParkingStore.checkHoliday(
                                    state.parking.effectiveStartTime
                                ).isHoliday
                            )
                            state.selectOption(.meter(segment, cost: cost))
                        }
                    }
                    .annotationTitles(.hidden)
                }
            }

            if state.map.filters.showTram, let tramData = state.parking.tramData {
                let routeCoords = tramData.routeCoordinates
                if routeCoords.count >= 2 {
                    MapPolyline(coordinates: routeCoords)
                        .stroke(
                            Color.tram,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [5, 3]))
                }

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
        .onMapCameraChange(frequency: .continuous) { context in
            currentSpan = context.region.span
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .including([.park])))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .safeAreaInset(edge: .top) {
            MapFilterBar()
                .padding(.top, 4)
        }
        .onChange(of: state.map.filters.showStreetMeters) {
            if state.map.filters.showStreetMeters {
                Task { await state.parking.fetchStreetSegments() }
            }
        }
        .onChange(of: state.parking.showMeters) {
            if state.parking.showMeters {
                state.map.filters.showStreetMeters = true
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
