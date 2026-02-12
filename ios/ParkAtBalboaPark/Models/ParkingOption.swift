import CoreLocation
import SwiftUI

/// Unified parking option wrapping either a lot recommendation or a street meter segment.
enum ParkingOption: Identifiable, Hashable {
    case lot(ParkingRecommendation)
    case meter(StreetSegment, cost: MeterCostResult)

    var id: String {
        switch self {
        case .lot(let rec): rec.lotSlug
        case .meter(let seg, _): "meter-\(seg.segmentId)"
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .lot(let rec): rec.coordinate
        case .meter(let seg, _): seg.coordinate
        }
    }

    var displayName: String {
        switch self {
        case .lot(let rec): rec.lotDisplayName
        case .meter(let seg, _): seg.streetName
        }
    }

    var costCents: Int {
        switch self {
        case .lot(let rec): rec.costCents
        case .meter(_, let cost): cost.costCents
        }
    }

    var costDisplay: String {
        switch self {
        case .lot(let rec): rec.costDisplay
        case .meter(_, let cost): cost.costDisplay
        }
    }

    var isFree: Bool {
        switch self {
        case .lot(let rec): rec.isFree
        case .meter(_, let cost): cost.isFree
        }
    }

    var costColor: Color {
        Color.costColor(cents: costCents, isFree: isFree)
    }
}
