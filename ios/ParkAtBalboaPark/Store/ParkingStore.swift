import CoreLocation
import Foundation
import OSLog
import SwiftUI

private let logger = Logger(subsystem: "com.parkatbalboapark.app", category: "ParkingStore")

@MainActor @Observable
class ParkingStore {
    // MARK: - Data

    var lots: [ParkingLot] = []
    var destinations: [Destination] = []
    var recommendations: [ParkingRecommendation] = []
    var enforcementActive: Bool = false
    var tramData: TramData? = nil
    var streetSegments: [StreetSegment] = []

    // MARK: - Selections

    var selectedDestination: Destination? = nil
    var selectedLot: ParkingRecommendation? = nil
    var visitHours: Int = 2
    var showFreeOnly: Bool = false

    // MARK: - UI State

    var isLoading: Bool = false

    /// Walking route polylines keyed by lot slug, populated by MapKit directions.
    var walkingRoutes: [String: [CLLocationCoordinate2D]] = [:]

    /// Elevation profiles keyed by lot slug, populated from Open-Meteo API.
    var elevationProfiles: [String: WalkingDirectionsService.ElevationProfile] = [:]

    // MARK: - Services

    private let api = APIClient.shared
    private var recommendationTask: Task<Void, Never>?

    // MARK: - Computed

    var displayedRecommendations: [ParkingRecommendation] {
        var recs = recommendations
        if showFreeOnly {
            recs = recs.filter { $0.isFree }
        }
        if selectedDestination != nil {
            recs.sort {
                ($0.walkingDistanceMeters ?? .infinity) < ($1.walkingDistanceMeters ?? .infinity)
            }
        }
        return recs
    }

    var lotAnnotations: [LotAnnotation] {
        if recommendations.isEmpty {
            return lots.map { lot in
                LotAnnotation(
                    lotSlug: lot.slug,
                    displayName: lot.displayName,
                    coordinate: lot.coordinate,
                    tier: nil,
                    costColor: .gray,
                    hasTram: lot.hasTramStop
                )
            }
        } else {
            return recommendations.map { rec in
                LotAnnotation(
                    lotSlug: rec.lotSlug,
                    displayName: rec.lotDisplayName,
                    coordinate: rec.coordinate,
                    tier: rec.tier,
                    costColor: rec.costColor,
                    hasTram: rec.hasTram
                )
            }
        }
    }

    // MARK: - Actions

    func selectDestination(_ dest: Destination?) {
        selectedDestination = dest
        selectedLot = nil
        walkingRoutes = [:]
        elevationProfiles = [:]
    }

    // MARK: - Data Loading

    func loadData() async {
        logger.info("loadData: starting API calls")

        // Run all three fetches concurrently, capture results independently
        async let lotsResult: Result<[ParkingLot], Error> = {
            do { return .success(try await api.fetchLots()) }
            catch { return .failure(error) }
        }()
        async let destinationsResult: Result<[Destination], Error> = {
            do { return .success(try await api.fetchDestinations()) }
            catch { return .failure(error) }
        }()
        async let enforcementResult: Result<EnforcementStatus, Error> = {
            do { return .success(try await api.fetchEnforcement()) }
            catch { return .failure(error) }
        }()

        let (lr, dr, er) = await (lotsResult, destinationsResult, enforcementResult)

        switch lr {
        case .success(let fetchedLots):
            self.lots = fetchedLots
            logger.info("loadData: loaded \(fetchedLots.count) lots")
        case .failure(let error):
            logger.error("loadData: lots failed – \(error)")
        }

        switch dr {
        case .success(let fetchedDestinations):
            self.destinations = fetchedDestinations
            logger.info("loadData: loaded \(fetchedDestinations.count) destinations")
        case .failure(let error):
            logger.error("loadData: destinations failed – \(error)")
        }

        switch er {
        case .success(let enforcement):
            self.enforcementActive = enforcement.active
            logger.info("loadData: enforcement active=\(enforcement.active)")
        case .failure(let error):
            logger.error("loadData: enforcement failed – \(error)")
        }

        logger.info("loadData: complete – \(self.lots.count) lots, \(self.destinations.count) destinations")
    }

    func fetchStreetSegments() async {
        guard streetSegments.isEmpty else { return }
        do {
            streetSegments = try await api.fetchStreetSegments()
        } catch {
            print("Failed to fetch street segments: \(error)")
        }
    }

    func fetchRecommendations(userType: UserType?, hasPass: Bool) async {
        recommendationTask?.cancel()

        let task = Task { @MainActor [weak self] in
            guard let self else { return }

            guard let userType else {
                self.recommendations = []
                return
            }

            self.isLoading = true

            do {
                try Task.checkCancellation()

                let response = try await self.api.fetchRecommendations(
                    userType: userType,
                    hasPass: hasPass,
                    destinationSlug: self.selectedDestination?.slug,
                    visitHours: self.visitHours
                )

                try Task.checkCancellation()

                self.recommendations = response.recommendations
                self.enforcementActive = response.enforcementActive
                self.isLoading = false

                // Enrich with real MapKit walking times and routes
                if let dest = self.selectedDestination {
                    self.walkingRoutes = [:]
                    Task {
                        let walkTimes = await WalkingDirectionsService.fetchWalkingTimes(
                            for: self.recommendations,
                            to: dest.coordinate
                        )
                        var routes: [String: [CLLocationCoordinate2D]] = [:]
                        for i in self.recommendations.indices {
                            let slug = self.recommendations[i].lotSlug
                            if let result = walkTimes[slug] {
                                self.recommendations[i].walkingDistanceMeters = result.distanceMeters
                                self.recommendations[i].walkingTimeSeconds = result.timeSeconds
                                self.recommendations[i].walkingTimeDisplay =
                                    WalkingDirectionsService.formatWalkTime(seconds: result.timeSeconds)
                                routes[slug] = result.routeCoordinates
                            }
                        }
                        self.walkingRoutes = routes

                        // Fetch elevation profiles for all routes
                        let profiles = await WalkingDirectionsService.fetchElevationProfiles(
                            for: routes
                        )
                        self.elevationProfiles = profiles
                    }
                } else {
                    self.walkingRoutes = [:]
                    self.elevationProfiles = [:]
                }
            } catch is CancellationError {
                // Task was cancelled; do not update state
            } catch {
                print("Failed to fetch recommendations: \(error)")
                self.isLoading = false
            }
        }

        recommendationTask = task
        await task.value
    }
}
