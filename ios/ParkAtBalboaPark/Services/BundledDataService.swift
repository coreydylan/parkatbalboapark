import Foundation

// MARK: - Bundled Data Service

/// Loads pre-bundled JSON data files from the app bundle for offline fallback.
///
/// The raw JSON files are expected in `Resources/Data/` within the app bundle:
/// - `lots.json` -- all parking lots
/// - `destinations.json` -- all destinations
/// - `tram-data.json` -- tram stops, schedule, and notes
/// - `holidays.json` -- enforcement holiday dates
/// - `pricing-rules.json` -- pricing tiers with effective dates
///
/// All methods return empty arrays or `nil` on failure, logging the error
/// to the console. This ensures the app degrades gracefully when bundled
/// data is missing or malformed.
enum BundledDataService {

    /// Load parking lots from the bundled `lots.json`.
    static func loadLots() -> [ParkingLot] {
        load("lots", type: [ParkingLot].self) ?? []
    }

    /// Load destinations from the bundled `destinations.json`.
    static func loadDestinations() -> [Destination] {
        load("destinations", type: [Destination].self) ?? []
    }

    /// Load tram route data from the bundled `tram-data.json`.
    static func loadTramData() -> TramData? {
        load("tram-data", type: TramData.self)
    }

    /// Load enforcement holiday dates from the bundled `holidays.json`.
    static func loadHolidays() -> [Holiday] {
        load("holidays", type: [Holiday].self) ?? []
    }

    /// Load pricing rules from the bundled `pricing-rules.json`.
    ///
    /// The JSON has a top-level `effectiveDate` that applies to all rules.
    /// Each returned `PricingRule` is stamped with that date.
    static func loadPricingRules() -> [PricingRule] {
        guard let file = load("pricing-rules", type: PricingRulesFile.self) else {
            return []
        }
        return file.rules.map { rule in
            PricingRule(
                tier: rule.tier,
                userType: rule.userType,
                durationType: rule.durationType,
                rateCents: rule.rateCents,
                maxDailyCents: rule.maxDailyCents,
                effectiveDate: file.effectiveDate,
                endDate: rule.endDate
            )
        }
    }

    // MARK: - Private

    /// Wrapper for the pricing-rules JSON file structure.
    private struct PricingRulesFile: Codable {
        let effectiveDate: String
        let rules: [PricingRule]
    }

    /// Generic JSON loader that reads from the app bundle.
    ///
    /// - Parameters:
    ///   - name: The filename without extension (e.g., "lots").
    ///   - type: The Decodable type to decode into.
    /// - Returns: The decoded value, or `nil` on any failure.
    private static func load<T: Decodable>(_ name: String, type: T.Type) -> T? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            print("BundledDataService: could not find \(name).json in bundle")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("BundledDataService: failed to decode \(name).json: \(error)")
            return nil
        }
    }
}
