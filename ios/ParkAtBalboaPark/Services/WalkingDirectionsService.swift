import CoreLocation
import MapKit

/// Fetches real walking directions from MapKit for lot → destination pairs.
enum WalkingDirectionsService {

    struct WalkingResult: @unchecked Sendable {
        let lotSlug: String
        let distanceMeters: Double
        let timeSeconds: Double
        let routeCoordinates: [CLLocationCoordinate2D]
    }

    struct ElevationProfile: Sendable {
        let gainMeters: Double
        let lossMeters: Double
    }

    // MARK: - Walking Directions

    /// Fetch walking ETAs from each lot coordinate to the destination.
    /// Uses MKDirections with `.walking` transport type for real route data.
    static func fetchWalkingTimes(
        for recommendations: [ParkingRecommendation],
        to destination: CLLocationCoordinate2D
    ) async -> [String: WalkingResult] {
        let destPlacemark = MKPlacemark(coordinate: destination)

        return await withTaskGroup(of: WalkingResult?.self) { group in
            for rec in recommendations {
                group.addTask {
                    let request = MKDirections.Request()
                    request.source = MKMapItem(
                        placemark: MKPlacemark(coordinate: rec.coordinate)
                    )
                    request.destination = MKMapItem(placemark: destPlacemark)
                    request.transportType = .walking

                    do {
                        let directions = MKDirections(request: request)
                        let response = try await directions.calculate()

                        guard let route = response.routes.first else { return nil }

                        let polyline = route.polyline
                        let count = polyline.pointCount
                        var coords = [CLLocationCoordinate2D](
                            repeating: CLLocationCoordinate2D(), count: count
                        )
                        polyline.getCoordinates(&coords, range: NSRange(location: 0, length: count))

                        return WalkingResult(
                            lotSlug: rec.lotSlug,
                            distanceMeters: route.distance,
                            timeSeconds: route.expectedTravelTime,
                            routeCoordinates: coords
                        )
                    } catch {
                        return nil
                    }
                }
            }

            var results: [String: WalkingResult] = [:]
            for await result in group {
                if let result {
                    results[result.lotSlug] = result
                }
            }
            return results
        }
    }

    // MARK: - Elevation

    /// Fetch elevation profiles for multiple routes using Open-Meteo API.
    /// Samples points along each route to reduce API calls.
    static func fetchElevationProfiles(
        for routes: [String: [CLLocationCoordinate2D]]
    ) async -> [String: ElevationProfile] {
        // Collect all sampled points with their lot slug + index
        var allPoints: [(slug: String, coord: CLLocationCoordinate2D)] = []
        var slugSampleCounts: [(slug: String, count: Int)] = []

        for (slug, coords) in routes {
            let sampled = sampleRoute(coords, maxPoints: 20)
            for coord in sampled {
                allPoints.append((slug: slug, coord: coord))
            }
            slugSampleCounts.append((slug: slug, count: sampled.count))
        }

        guard !allPoints.isEmpty else { return [:] }

        // Query Open-Meteo for all points in one request
        let lats = allPoints.map { String(format: "%.6f", $0.coord.latitude) }.joined(separator: ",")
        let lngs = allPoints.map { String(format: "%.6f", $0.coord.longitude) }.joined(separator: ",")

        guard var components = URLComponents(string: "https://api.open-meteo.com/v1/elevation") else {
            return [:]
        }
        components.queryItems = [
            URLQueryItem(name: "latitude", value: lats),
            URLQueryItem(name: "longitude", value: lngs),
        ]

        guard let url = components.url else { return [:] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            let elevations = response.elevation

            guard elevations.count == allPoints.count else { return [:] }

            // Split elevations back into per-route arrays
            var profiles: [String: ElevationProfile] = [:]
            var offset = 0

            for (slug, count) in slugSampleCounts {
                let routeElevations = Array(elevations[offset..<(offset + count)])
                offset += count

                var gain: Double = 0
                var loss: Double = 0
                for i in 1..<routeElevations.count {
                    let diff = routeElevations[i] - routeElevations[i - 1]
                    if diff > 0 { gain += diff }
                    else { loss += abs(diff) }
                }

                profiles[slug] = ElevationProfile(gainMeters: gain, lossMeters: loss)
            }

            return profiles
        } catch {
            print("Elevation fetch failed: \(error)")
            return [:]
        }
    }

    // MARK: - Helpers

    /// Format seconds into a display string like "12 min walk".
    static func formatWalkTime(seconds: Double) -> String {
        let minutes = Int(ceil(seconds / 60))
        return "\(minutes) min walk"
    }

    /// Evenly sample points along a route polyline.
    private static func sampleRoute(
        _ coords: [CLLocationCoordinate2D], maxPoints: Int
    ) -> [CLLocationCoordinate2D] {
        guard coords.count > maxPoints else { return coords }
        let step = Double(coords.count - 1) / Double(maxPoints - 1)
        return (0..<maxPoints).map { i in
            coords[min(Int(Double(i) * step), coords.count - 1)]
        }
    }

    /// Response from Open-Meteo elevation API.
    private struct OpenMeteoResponse: Decodable {
        let elevation: [Double]
    }
}
