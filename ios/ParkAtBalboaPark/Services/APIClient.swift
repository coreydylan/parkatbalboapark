import Foundation

// MARK: - API Client

/// Thread-safe API client for the Park at Balboa Park Next.js backend.
///
/// Uses async/await with URLSession to hit the deployed API routes.
/// All public methods throw ``APIError`` on failure.
///
/// Usage:
/// ```swift
/// let lots = try await APIClient.shared.fetchLots()
/// ```
actor APIClient {
    static let shared = APIClient()

    private let baseURL: URL
    private let decoder: JSONDecoder
    private let session: URLSession

    // MARK: - Initialization

    private init() {
        // Default to the deployed Vercel URL.
        // For local development, change to http://localhost:3000
        self.baseURL = URL(string: "https://parkatbalboapark.vercel.app")!

        let decoder = JSONDecoder()
        // The Next.js API routes transform all responses to camelCase,
        // so the default key decoding strategy is correct.
        self.decoder = decoder

        self.session = URLSession.shared
    }

    // MARK: - Public Endpoints

    /// Fetch all parking lots.
    ///
    /// Calls `GET /api/lots` and unwraps the `{ lots: [...] }` envelope.
    func fetchLots() async throws -> [ParkingLot] {
        let response: LotsResponse = try await fetch("/api/lots")
        return response.lots
    }

    /// Fetch all destinations, optionally filtered by area.
    ///
    /// Calls `GET /api/destinations` with an optional `area` query parameter.
    /// - Parameter area: If provided, only destinations in this area are returned.
    func fetchDestinations(area: DestinationArea? = nil) async throws -> [Destination] {
        var queryItems: [URLQueryItem]?
        if let area {
            queryItems = [URLQueryItem(name: "area", value: area.rawValue)]
        }
        let response: DestinationsResponse = try await fetch("/api/destinations", queryItems: queryItems)
        return response.destinations
    }

    /// Fetch parking recommendations based on user profile and destination.
    ///
    /// Calls `GET /api/recommend` with the provided parameters.
    /// - Parameters:
    ///   - userType: The visitor's role (resident, nonresident, staff, volunteer, ada).
    ///   - hasPass: Whether the user has a parking pass.
    ///   - destinationSlug: Optional slug of the target destination.
    ///   - visitHours: Expected duration of the visit in hours.
    /// - Returns: A ``RecommendationResponse`` containing ranked lots and enforcement status.
    func fetchRecommendations(
        userType: UserType,
        hasPass: Bool = false,
        destinationSlug: String? = nil,
        visitHours: Int = 2
    ) async throws -> RecommendationResponse {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "user_type", value: userType.rawValue),
            URLQueryItem(name: "has_pass", value: hasPass ? "true" : "false"),
            URLQueryItem(name: "visit_hours", value: String(visitHours)),
        ]
        if let destinationSlug {
            queryItems.append(URLQueryItem(name: "destination", value: destinationSlug))
        }
        return try await fetch("/api/recommend", queryItems: queryItems)
    }

    /// Fetch current enforcement status (active hours, next holiday).
    ///
    /// Calls `GET /api/enforcement`.
    func fetchEnforcement() async throws -> EnforcementStatus {
        try await fetch("/api/enforcement")
    }

    // MARK: - Private Helpers

    /// Generic fetch helper that builds a URL, performs the request, and decodes the response.
    ///
    /// - Parameters:
    ///   - path: The API path relative to the base URL (e.g., "/api/lots").
    ///   - queryItems: Optional query parameters to append.
    /// - Returns: A decoded value of type `T`.
    /// - Throws: ``APIError`` for HTTP errors, URL issues, or decoding failures.
    private func fetch<T: Decodable>(
        _ path: String,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL
        }

        // Only set queryItems if the array is non-nil and non-empty to avoid
        // appending an empty "?" to the URL.
        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.httpError(statusCode: 0)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Private Response Wrappers

    /// Envelope for `GET /api/lots`.
    private struct LotsResponse: Codable {
        let lots: [ParkingLot]
    }

    /// Envelope for `GET /api/destinations`.
    private struct DestinationsResponse: Codable {
        let destinations: [Destination]
    }
}

// MARK: - API Error

/// Errors that can occur when communicating with the Park at Balboa Park API.
enum APIError: LocalizedError {
    /// The server returned a non-2xx HTTP status code.
    case httpError(statusCode: Int)

    /// A valid URL could not be constructed from the given path and parameters.
    case invalidURL

    /// The response body could not be decoded into the expected type.
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .httpError(let code):
            "Server error (HTTP \(code))"
        case .invalidURL:
            "Invalid URL"
        case .decodingError(let error):
            "Failed to parse response: \(error.localizedDescription)"
        }
    }
}
