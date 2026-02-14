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
                        label: annotation.rank.map { "\($0)" } ?? "P",
                        tier: annotation.tier,
                        costColor: annotation.rank != nil ? .accentColor : annotation.costColor,
                        isSelected: {
                            if case .lot(let rec) = state.parking.selectedOption {
                                return rec.lotSlug == annotation.lotSlug
                            }
                            return false
                        }(),
                        hasTram: annotation.hasTram,
                        isRanked: annotation.rank != nil
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

            if state.parking.showMeters {
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

        }
        .onMapCameraChange(frequency: .continuous) { context in
            currentSpan = context.region.span
        }
        .mapStyle(mapStyleForOption(state.map.mapStyle))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .safeAreaInset(edge: .top) {
            HStack(spacing: 12) {
                MapStylePicker()
                Spacer()
                locationButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
        .onChange(of: state.parking.showMeters) {
            if state.parking.showMeters {
                Task { await state.parking.fetchStreetSegments() }
            }
        }
    }

    private var locationButton: some View {
        Button {
            withAnimation(.smooth) {
                state.map.cameraPosition = .userLocation(
                    fallback: .region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: 32.7341, longitude: -117.1446),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                )
            }
        } label: {
            Image(systemName: "location.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.accentColor)
                .frame(width: 36, height: 36)
        }
        .glassEffect(.regular.interactive())
    }

    private func mapStyleForOption(_ option: MapStyleOption) -> MapStyle {
        let parkPOIs = PointOfInterestCategories.including([.park])
        switch option {
        case .standard:
            return .standard(elevation: .realistic, pointsOfInterest: parkPOIs)
        case .satellite:
            return .imagery(elevation: .realistic)
        case .hybrid:
            return .hybrid(elevation: .realistic, pointsOfInterest: parkPOIs)
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
    let rank: Int?  // 1-based rank in displayed options (nil = unranked)

    var id: String { lotSlug }
}
