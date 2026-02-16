import MapKit
import SwiftUI

/// Apple Maps-style progressive disclosure detail view for a parking lot.
struct LotDetailView: View {
    @Environment(AppState.self) private var state
    let recommendation: ParkingRecommendation

    @State private var sectionAppeared = false
    @State private var rawElevations: [Double]? = nil
    @State private var lookAroundScene: MKLookAroundScene?

    private var lot: ParkingLot? {
        state.parking.lotLookup[recommendation.lotSlug]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Look Around header with background fade
                LotPhotoCarousel(scene: lookAroundScene)
                    .ignoresSafeArea(edges: .top)
                    .sectionAnimation(index: 0, appeared: sectionAppeared)

                // Title + Address
                titleSection
                    .sectionAnimation(index: 1, appeared: sectionAppeared)

                // Stats row: tier badge, walking time, tram
                statsRow
                    .sectionAnimation(index: 2, appeared: sectionAppeared)

                // Cost badge (large)
                costSection
                    .sectionAnimation(index: 3, appeared: sectionAppeared)

                // Pricing explanation
                PricingExplanationView(
                    recommendation: recommendation,
                    lot: lot,
                    userType: state.profile.effectiveUserType ?? .nonresident,
                    isVerifiedResident: state.profile.isVerifiedResident,
                    hasPass: state.profile.hasPass,
                    startTime: state.parking.effectiveStartTime,
                    visitHours: Double(state.parking.visitDurationMinutes) / 60.0,
                    enforcementMessage: state.parking.enforcementMessage,
                    pricingRules: state.parking.cachedPricingRules
                )
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .sectionAnimation(index: 4, appeared: sectionAppeared)

                // Elevation chart
                if let elevations = rawElevations, elevations.count > 2 {
                    ElevationChartView(elevations: elevations)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .sectionAnimation(index: 5, appeared: sectionAppeared)
                }

                // Rate comparison
                if state.parking.pricingDataLoaded {
                    RateComparisonSection(
                        recommendation: recommendation,
                        lot: lot,
                        startTime: state.parking.effectiveStartTime,
                        visitHours: Double(state.parking.visitDurationMinutes) / 60.0,
                        pricingRules: state.parking.cachedPricingRules,
                        tierAssignments: state.parking.cachedTierAssignments,
                        enforcementPeriods: state.parking.cachedEnforcementPeriods,
                        holidays: state.parking.cachedHolidays,
                        userProfile: state.profile
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .sectionAnimation(index: 6, appeared: sectionAppeared)
                }

                // Tier change timeline
                if let lot, let history = lot.tierHistory, !history.isEmpty {
                    let transitions = TierTransition.from(tierHistory: history)
                    if !transitions.isEmpty {
                        TierChangeTimeline(
                            currentTier: recommendation.tier,
                            transitions: transitions
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .sectionAnimation(index: 7, appeared: sectionAppeared)
                    }
                }

                // Amenities grid
                if let lot {
                    AmenitiesGrid(lot: lot, recommendation: recommendation)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .sectionAnimation(index: 8, appeared: sectionAppeared)
                }

                // Data freshness footer
                DataFreshnessFooter()
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                    .sectionAnimation(index: 9, appeared: sectionAppeared)
            }
        }
        .scrollIndicators(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sensoryFeedback(.impact(weight: .medium), trigger: sectionAppeared)
        .task {
            // Stagger section appearance
            try? await Task.sleep(for: .milliseconds(100))
            withAnimation(.easeOut(duration: 0.3)) {
                sectionAppeared = true
            }

            // Fetch Look Around scene
            lookAroundScene = await LookAroundService.fetchScene(
                lat: recommendation.lat,
                lng: recommendation.lng
            )

            // Fetch raw elevation data for chart
            if let coords = state.parking.walkingRoutes[recommendation.lotSlug] {
                rawElevations = await WalkingDirectionsService.fetchRawElevations(coords: coords)
            }
        }
    }

    // MARK: - Title Section (name + address below image)

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(recommendation.lotDisplayName)
                .font(.title2.weight(.bold))
            if let lot {
                Text(lot.address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            // Tier badge
            Text(recommendation.tier.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(recommendation.tier.color, in: Capsule())

            // Walking time
            if let walkTime = recommendation.walkingTimeDisplay {
                Label(walkTime, systemImage: "figure.walk")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Tram
            if recommendation.hasTram {
                Label("Tram", systemImage: "tram.fill")
                    .font(.caption)
                    .foregroundStyle(Color.tram)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(statsAccessibilityLabel)
    }

    private var statsAccessibilityLabel: String {
        var parts = [recommendation.tier.name]
        if let walkTime = recommendation.walkingTimeDisplay {
            parts.append("\(walkTime) walk")
        }
        if recommendation.hasTram {
            parts.append("Tram available")
        }
        return parts.joined(separator: ", ")
    }

    // MARK: - Cost Section

    private var costSection: some View {
        HStack(spacing: 12) {
            CostBadge(
                costDisplay: recommendation.costDisplay,
                costCents: recommendation.costCents,
                isFree: recommendation.isFree
            )
            .scaleEffect(1.2, anchor: .leading)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(recommendation.isFree ? "Free parking" : "Cost: \(recommendation.costDisplay)")
    }
}

