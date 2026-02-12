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
    var showFreeOnly: Bool = false

    // MARK: - Time Window

    var startTime: Date = ParkingStore.nextTenMinuteMark()
    var endTime: Date = ParkingStore.nextTenMinuteMark().addingTimeInterval(2 * 3600)
    /// `nil` = "Park Now" (today). Set = planning a future trip.
    var tripDate: Date? = nil

    // MARK: - UI State

    var isLoading: Bool = false

    /// Walking route polylines keyed by lot slug, populated by MapKit directions.
    var walkingRoutes: [String: [CLLocationCoordinate2D]] = [:]

    /// Elevation profiles keyed by lot slug, populated from Open-Meteo API.
    var elevationProfiles: [String: WalkingDirectionsService.ElevationProfile] = [:]

    // MARK: - Services

    private let api = APIClient.shared
    private let supabase = SupabaseClient.shared
    private var recommendationTask: Task<Void, Never>?

    // MARK: - Time Window Computed Properties

    /// The actual start time for the visit, combining tripDate + startTime components.
    var effectiveStartTime: Date {
        guard let tripDate else { return startTime }
        return Self.combineDateAndTime(date: tripDate, time: startTime)
    }

    /// The actual end time for the visit, combining tripDate + endTime components.
    var effectiveEndTime: Date {
        guard let tripDate else { return endTime }
        return Self.combineDateAndTime(date: tripDate, time: endTime)
    }

    /// Visit duration in minutes.
    var visitDurationMinutes: Int {
        max(0, Int(effectiveEndTime.timeIntervalSince(effectiveStartTime) / 60))
    }

    /// Hours of the visit that fall within the enforcement window.
    var enforcedVisitHours: Double {
        Self.computeEnforcedHours(start: effectiveStartTime, end: effectiveEndTime)
    }

    /// Human-readable visit summary, e.g. "6:40 PM → 9:00 PM (2h 20m)".
    var visitSummary: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = PricingEngine.pacificTimeZone

        let startStr = formatter.string(from: effectiveStartTime)
        let endStr = formatter.string(from: effectiveEndTime)
        let totalMinutes = visitDurationMinutes
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60

        let durationStr: String
        if hours > 0 && mins > 0 {
            durationStr = "\(hours)h \(mins)m"
        } else if hours > 0 {
            durationStr = "\(hours)h"
        } else {
            durationStr = "\(mins)m"
        }

        return "\(startStr) → \(endStr) (\(durationStr))"
    }

    /// Message about enforcement boundaries, e.g. "Free after 8 PM" or "Holiday – free all day".
    var enforcementMessage: String? {
        let start = effectiveStartTime
        let end = effectiveEndTime

        // Check holiday
        let (isHoliday, holidayName) = Self.checkHoliday(start)
        if isHoliday {
            return "Holiday\(holidayName.map { " (\($0))" } ?? "") – free all day"
        }

        let (enfStart, enfEnd) = Self.enforcementWindow(for: start)
        let cal = Self.pacificCalendar
        let startHour = cal.component(.hour, from: start)
        let endHour = cal.component(.hour, from: end)
        let endMinute = cal.component(.minute, from: end)

        // Entirely outside enforcement
        if startHour >= enfEnd || (endHour < enfStart && endMinute == 0) || endHour < enfStart {
            return "Outside enforcement hours – free parking"
        }

        // Visit extends past enforcement end
        let endTotalMin = endHour * 60 + endMinute
        let enfEndMin = enfEnd * 60
        if endTotalMin > enfEndMin {
            let enfEndFormatted = Self.formatHour(enfEnd)
            return "Free after \(enfEndFormatted)"
        }

        // Visit starts before enforcement
        if startHour < enfStart {
            let enfStartFormatted = Self.formatHour(enfStart)
            return "Free before \(enfStartFormatted)"
        }

        return nil
    }

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

    /// Reset start time to next 10-minute mark for "Park Now" flow.
    func resetToNow() {
        tripDate = nil
        startTime = Self.nextTenMinuteMark()
        endTime = startTime.addingTimeInterval(2 * 3600)
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

    // MARK: - Recommendations (Direct Supabase RPC)

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

                // Compute query time and visit hours for the RPC
                let enforced = self.enforcedVisitHours
                let totalHours = Double(self.visitDurationMinutes) / 60.0

                let queryTime: Date
                let visitHours: Double

                if enforced > 0 {
                    // Some portion is within enforcement — send a time inside the window
                    let (enfStart, _) = Self.enforcementWindow(for: self.effectiveStartTime)
                    let cal = Self.pacificCalendar
                    let startHour = cal.component(.hour, from: self.effectiveStartTime)
                    queryTime = startHour >= enfStart
                        ? self.effectiveStartTime
                        : cal.date(
                            bySettingHour: enfStart, minute: 0, second: 0,
                            of: self.effectiveStartTime)!
                    visitHours = enforced
                } else {
                    queryTime = self.effectiveStartTime
                    visitHours = totalHours
                }

                // Try direct Supabase RPC first, fall back to Vercel API
                let recs: [ParkingRecommendation]
                let isEnforced: Bool

                do {
                    recs = try await self.fetchRecommendationsDirect(
                        userType: userType,
                        hasPass: hasPass,
                        queryTime: queryTime,
                        visitHours: visitHours
                    )
                    isEnforced = enforced > 0
                } catch {
                    logger.warning("Direct RPC failed, falling back to Vercel API: \(error)")
                    let response = try await self.api.fetchRecommendations(
                        userType: userType,
                        hasPass: hasPass,
                        destinationSlug: self.selectedDestination?.slug,
                        visitHours: max(1, Int(ceil(totalHours)))
                    )
                    recs = response.recommendations
                    isEnforced = response.enforcementActive
                }

                try Task.checkCancellation()

                self.recommendations = recs
                self.enforcementActive = isEnforced
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

    // MARK: - Direct Supabase RPC

    private func fetchRecommendationsDirect(
        userType: UserType,
        hasPass: Bool,
        queryTime: Date,
        visitHours: Double
    ) async throws -> [ParkingRecommendation] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var params: [String: Any] = [
            "p_user_type": userType.rawValue,
            "p_has_pass": hasPass,
            "p_query_time": formatter.string(from: queryTime),
            "p_visit_hours": visitHours,
        ]

        if let slug = selectedDestination?.slug {
            params["p_destination_slug"] = slug
        }

        let rpcResults: [RPCRecommendation] = try await supabase.callRPC(
            functionName: "get_parking_recommendations",
            params: params
        )

        return rpcResults.map { rpc in
            ParkingRecommendation(
                lotSlug: rpc.lotSlug,
                lotName: rpc.lotName,
                lotDisplayName: rpc.lotDisplayName,
                lat: rpc.lat,
                lng: rpc.lng,
                tier: LotTier(rawValue: rpc.tier) ?? .free,
                costCents: rpc.costCents,
                costDisplay: rpc.costDisplay,
                isFree: rpc.isFree,
                walkingDistanceMeters: rpc.walkingDistanceMeters.map(Double.init),
                walkingTimeSeconds: rpc.walkingTimeSeconds.map(Double.init),
                walkingTimeDisplay: rpc.walkingTimeDisplay,
                hasTram: rpc.hasTram,
                tramTimeMinutes: rpc.tramTimeMinutes,
                score: rpc.score,
                tips: rpc.tips
            )
        }
    }

    // MARK: - Time Helpers

    static let pacificCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = PricingEngine.pacificTimeZone
        return cal
    }()

    /// Rounds up to the next 10-minute mark.
    static func nextTenMinuteMark(from date: Date = Date()) -> Date {
        let cal = pacificCalendar
        var comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minute = comps.minute ?? 0
        let remainder = minute % 10
        if remainder == 0 {
            comps.minute = minute + 10
        } else {
            comps.minute = minute + (10 - remainder)
        }
        comps.second = 0
        return cal.date(from: comps) ?? date
    }

    /// Combine the date portion of one Date with the time portion of another (in Pacific time).
    private static func combineDateAndTime(date: Date, time: Date) -> Date {
        let cal = pacificCalendar
        let dateComps = cal.dateComponents([.year, .month, .day], from: date)
        let timeComps = cal.dateComponents([.hour, .minute], from: time)
        var combined = DateComponents()
        combined.year = dateComps.year
        combined.month = dateComps.month
        combined.day = dateComps.day
        combined.hour = timeComps.hour
        combined.minute = timeComps.minute
        combined.second = 0
        return cal.date(from: combined) ?? date
    }

    /// Snap a date to the nearest 10-minute interval.
    static func snapToTenMinutes(_ date: Date) -> Date {
        let cal = pacificCalendar
        var comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minute = comps.minute ?? 0
        comps.minute = (minute / 10) * 10
        comps.second = 0
        return cal.date(from: comps) ?? date
    }

    // MARK: - Enforcement Helpers

    /// Returns enforcement start/end hours for a given date.
    /// Before March 2, 2026: 8am–8pm. March 2, 2026+: 8am–6pm.
    static func enforcementWindow(for date: Date) -> (start: Int, end: Int) {
        let cal = pacificCalendar
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let year = comps.year ?? 2025
        let month = comps.month ?? 1
        let day = comps.day ?? 1

        // March 2, 2026 = (2026, 3, 2)
        if year > 2026 || (year == 2026 && (month > 3 || (month == 3 && day >= 2))) {
            return (start: 8, end: 18)
        }
        return (start: 8, end: 20)
    }

    /// Checks if a date is a known parking enforcement holiday.
    static func checkHoliday(_ date: Date) -> (isHoliday: Bool, name: String?) {
        let cal = pacificCalendar
        let month = cal.component(.month, from: date)
        let day = cal.component(.day, from: date)
        let weekday = cal.component(.weekday, from: date) // Sunday=1, Monday=2, ...
        let weekOfMonth = cal.component(.weekdayOrdinal, from: date)

        // Fixed-date holidays
        if month == 1 && day == 1 { return (true, "New Year's Day") }
        if month == 7 && day == 4 { return (true, "Independence Day") }
        if month == 11 && day == 11 { return (true, "Veterans Day") }
        if month == 12 && day == 25 { return (true, "Christmas Day") }

        // Floating holidays
        // MLK Day: 3rd Monday of January
        if month == 1 && weekday == 2 && weekOfMonth == 3 { return (true, "MLK Day") }
        // Presidents' Day: 3rd Monday of February
        if month == 2 && weekday == 2 && weekOfMonth == 3 { return (true, "Presidents' Day") }
        // Memorial Day: Last Monday of May
        if month == 5 && weekday == 2 {
            // Check if this is the last Monday by seeing if there's another Monday in the month
            let nextWeek = cal.date(byAdding: .day, value: 7, to: date)!
            if cal.component(.month, from: nextWeek) != 5 {
                return (true, "Memorial Day")
            }
        }
        // Labor Day: 1st Monday of September
        if month == 9 && weekday == 2 && weekOfMonth == 1 { return (true, "Labor Day") }
        // Thanksgiving: 4th Thursday of November
        if month == 11 && weekday == 5 && weekOfMonth == 4 { return (true, "Thanksgiving") }

        return (false, nil)
    }

    /// Computes hours of enforcement overlap for a visit window.
    static func computeEnforcedHours(start: Date, end: Date) -> Double {
        guard end > start else { return 0 }

        // Check holiday
        let (isHoliday, _) = checkHoliday(start)
        if isHoliday { return 0 }

        let cal = pacificCalendar
        let (enfStartHour, enfEndHour) = enforcementWindow(for: start)

        let startHour = cal.component(.hour, from: start)
        let startMinute = cal.component(.minute, from: start)
        let endHour = cal.component(.hour, from: end)
        let endMinute = cal.component(.minute, from: end)

        let visitStartMin = startHour * 60 + startMinute
        let visitEndMin = endHour * 60 + endMinute
        let enfStartMin = enfStartHour * 60
        let enfEndMin = enfEndHour * 60

        // Calculate overlap
        let overlapStart = max(visitStartMin, enfStartMin)
        let overlapEnd = min(visitEndMin, enfEndMin)

        if overlapEnd <= overlapStart { return 0 }

        return Double(overlapEnd - overlapStart) / 60.0
    }

    /// Format an hour integer as a time string (e.g. 20 → "8 PM", 18 → "6 PM").
    private static func formatHour(_ hour: Int) -> String {
        let h = hour > 12 ? hour - 12 : hour
        let period = hour >= 12 ? "PM" : "AM"
        return "\(h) \(period)"
    }
}

// MARK: - RPC Response Decoding

/// Intermediate struct for decoding the Supabase RPC response.
/// Handles type differences between Postgres and the app's model.
private struct RPCRecommendation: Decodable {
    let lotSlug: String
    let lotName: String
    let lotDisplayName: String
    let lat: Double
    let lng: Double
    let tier: Int
    let costCents: Int
    let costDisplay: String
    let isFree: Bool
    let walkingDistanceMeters: Int?
    let walkingTimeSeconds: Int?
    let walkingTimeDisplay: String?
    let hasTram: Bool
    let tramTimeMinutes: Int?
    let score: Double
    let tips: [String]
}
