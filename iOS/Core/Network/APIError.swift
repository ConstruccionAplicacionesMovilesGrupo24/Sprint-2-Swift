//
//  APIError.swift
//  CampusMeal
//

import Foundation

// Mirrors the error contract in `backend-architecture-and-frontend-integration.md`
// section 17 (HTTP status mapping) and the error body shape in section 9.
enum APIError: Error, Equatable {
    case invalidResponse
    case decodingFailed
    case validation(message: String)
    case unauthorized
    case forbidden
    case notFound
    case conflict(message: String)
    case server(statusCode: Int)
    case transport(String)

    struct ServerErrorBody: Decodable {
        let statusCode: Int
        let code: String
        let message: String
        let timestamp: String
        let path: String
    }

    static func fromHTTP(statusCode: Int, data: Data?) -> APIError {
        let message = data.flatMap { try? JSONDecoder().decode(ServerErrorBody.self, from: $0) }?.message

        switch statusCode {
        case 400, 422:
            return .validation(message: message ?? "Invalid request")
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 409:
            return .conflict(message: message ?? "Conflict")
        default:
            return .server(statusCode: statusCode)
        }
    }
}
