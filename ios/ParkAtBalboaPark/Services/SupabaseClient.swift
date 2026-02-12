import Foundation
import OSLog

private let logger = Logger(subsystem: "com.parkatbalboapark.app", category: "SupabaseClient")

/// Direct client for calling Supabase REST API RPCs.
///
/// Bypasses the Vercel API proxy to call the Supabase RPC endpoint directly.
/// Uses the publishable anon key for authentication.
actor SupabaseClient {
    static let shared = SupabaseClient()

    private let baseURL = URL(string: "https://aoextxaovxuzrpxxovmr.supabase.co")!
    private let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvZXh0eGFvdnh1enJweHhvdm1yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA3ODk1MDEsImV4cCI6MjA4NjM2NTUwMX0.mycHo5SeMaPPLZDpnywWS9PLVQ6dbFOP6oKomPxPbGQ"
    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        self.session = URLSession.shared

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    /// Call a Supabase RPC function and decode the response.
    ///
    /// - Parameters:
    ///   - functionName: The RPC function name (e.g., "get_parking_recommendations").
    ///   - params: A dictionary of parameters to pass as the JSON body.
    /// - Returns: The decoded response of type `T`.
    func callRPC<T: Decodable>(
        functionName: String,
        params: [String: Any] = [:]
    ) async throws -> T {
        let url = baseURL.appendingPathComponent("/rest/v1/rpc/\(functionName)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if !params.isEmpty {
            request.httpBody = try JSONSerialization.data(withJSONObject: params)
        }

        logger.debug("RPC call: \(functionName)")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.httpError(statusCode: 0)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let body = String(data: data, encoding: .utf8) {
                logger.error("RPC \(functionName) failed (\(httpResponse.statusCode)): \(body)")
            }
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            if let body = String(data: data, encoding: .utf8) {
                logger.error("RPC \(functionName) decode error: \(error)\nBody: \(body)")
            }
            throw APIError.decodingError(error)
        }
    }
}
