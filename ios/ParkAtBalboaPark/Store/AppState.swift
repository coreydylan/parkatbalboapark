import Foundation
@preconcurrency import MapKit
import SwiftUI

@MainActor @Observable
class AppState {
    let profile = UserProfile()
    let parking = ParkingStore()
    let map = MapState()
    let locationService = LocationService()
    let morph = CardMorphState()

    var expandedPreviewSlug: String? = nil
    var detailRecommendation: ParkingRecommendation? = nil

    init() {
        profile.appOpenCount += 1
        Task { await loadData() }
    }

    private var lastApiUserType: UserType?
    private var lastHasPass: Bool = false

    func loadData() async {
        profile.recordVisit()
        await parking.loadData()
        await fetchRecommendations()
    }

    func fetchRecommendations() async {
        lastApiUserType = profile.apiUserType
        lastHasPass = profile.hasPass
        await parking.fetchRecommendations(
            userType: profile.apiUserType,
            hasPass: profile.hasPass
        )
    }

    func selectDestination(_ dest: Destination?) {
        if morph.fullscreenLotSlug != nil {
            closeDetail()
        }
        expandedPreviewSlug = nil
        parking.selectDestination(dest)
    }

    func refreshIfProfileChanged() {
        guard parking.selectedDestination != nil,
              !parking.recommendations.isEmpty
        else { return }
        let currentType = profile.apiUserType
        let currentPass = profile.hasPass
        guard currentType != lastApiUserType || currentPass != lastHasPass else { return }
        Task { await fetchRecommendations() }
    }

    func selectOption(_ option: ParkingOption?) {
        parking.selectedOption = option
        // Keep selectedLot in sync for backwards compatibility
        if case .lot(let rec) = option {
            parking.selectedLot = rec
        } else {
            parking.selectedLot = nil
        }
        if let option {
            if let dest = parking.selectedDestination {
                map.fitRoute(from: option.coordinate, to: dest.coordinate)
            } else {
                map.focusOn(option.coordinate)
            }
        }
    }

    func selectLot(_ recommendation: ParkingRecommendation?) {
        if let rec = recommendation {
            selectOption(.lot(rec))
        } else {
            selectOption(nil)
        }
    }

    /// Step 1→2: Expand a card in-place to show preview + key data.
    func expandPreview(for recommendation: ParkingRecommendation) {
        // Tapping the same expanded card → collapse
        if expandedPreviewSlug == recommendation.lotSlug {
            collapsePreview()
            return
        }
        expandedPreviewSlug = recommendation.lotSlug
        selectOption(.lot(recommendation))
        map.startFlyover(
            lotCoordinate: recommendation.coordinate,
            destinationCoordinate: parking.selectedDestination?.coordinate
        )
    }

    /// Collapse the expanded preview back to compact card.
    func collapsePreview() {
        expandedPreviewSlug = nil
        map.stopFlyover()
        if let lot = parking.selectedLot {
            map.focusOn(lot.coordinate)
        }
    }

    /// Open the lot detail sheet.
    func openDetail(for recommendation: ParkingRecommendation) {
        selectOption(.lot(recommendation))
        detailRecommendation = recommendation
        Task { await parking.fetchPricingData() }
    }

    /// Close the lot detail sheet.
    func closeDetail() {
        detailRecommendation = nil
    }

    /// Swipe between expanded cards in the recommendation list.
    func expandedSwipe(direction: SwipeDirection) {
        guard let currentSlug = expandedPreviewSlug else { return }
        let options = parking.displayedOptions
        guard let currentIndex = options.firstIndex(where: { $0.id == currentSlug }) else { return }

        let targetIndex: Int
        switch direction {
        case .left:
            targetIndex = currentIndex + 1
        case .right:
            targetIndex = currentIndex - 1
        }

        guard targetIndex >= 0, targetIndex < options.count else { return }
        let targetOption = options[targetIndex]

        if case .lot(let rec) = targetOption {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) {
                expandPreview(for: rec)
            }
        }
    }
}

enum SwipeDirection {
    case left, right
}
