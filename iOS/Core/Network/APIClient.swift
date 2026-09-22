//
//  APIClient.swift
//  CampusMeal
//

import Foundation

// Async/await networking layer talking to the CampusMeal backend
// (`/api/v1` base — section 9 of backend-architecture-and-frontend-integration.md).
//
// This client only knows how to send a request, decode/throw a typed result,
// and retry once after a refresh. It has no knowledge of Keychain or the
// `auth/refresh` contract: `authorizationProvider` and `refreshHandler` are
// injected by `Core/Session` (SessionManager) so Session depends on Network,
// never the other way around.
final class APIClient {
    static let shared = APIClient(baseURL: URL(string: "http://localhost:3000/api/v1/")!)

    private let baseURL: URL
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    var authorizationProvider: (() -> String?)?
    // Returns true once a new access token is available. Called at most once
    // per request so a failing refresh can't cause a retry loop.
    var refreshHandler: (() async -> Bool)?

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func send<Response: Decodable>(_ endpoint: APIEndpoint) async throws -> Response {
        do {
            return try await performSend(endpoint)
        } catch APIError.unauthorized {
            guard endpoint.requiresAuth, let refreshHandler, await refreshHandler() else {
                throw APIError.unauthorized
            }
            return try await performSend(endpoint)
        }
    }

    // For endpoints with no response body (e.g. logout → 204).
    func sendNoContent(_ endpoint: APIEndpoint) async throws {
        do {
            try await performSendNoContent(endpoint)
        } catch APIError.unauthorized {
            guard endpoint.requiresAuth, let refreshHandler, await refreshHandler() else {
                throw APIError.unauthorized
            }
            try await performSendNoContent(endpoint)
        }
    }

    private func performSend<Response: Decodable>(_ endpoint: APIEndpoint) async throws -> Response {
        let (data, response) = try await execute(endpoint)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        try validate(httpResponse, data: data)

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }

    private func performSendNoContent(_ endpoint: APIEndpoint) async throws {
        let (data, response) = try await execute(endpoint)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        try validate(httpResponse, data: data)
    }

    private func execute(_ endpoint: APIEndpoint) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if endpoint.requiresAuth, let token = authorizationProvider?() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = endpoint.body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        do {
            return try await session.data(for: request)
        } catch {
            throw APIError.transport(error.localizedDescription)
        }
    }

    private func validate(_ response: HTTPURLResponse, data: Data) throws {
        guard (200...299).contains(response.statusCode) else {
            throw APIError.fromHTTP(statusCode: response.statusCode, data: data)
        }
    }
}

// JSONEncoder.encode requires a concrete Encodable type; this erases the
// existential `Encodable` stored on APIEndpoint.body back into one.
private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        encodeClosure = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
