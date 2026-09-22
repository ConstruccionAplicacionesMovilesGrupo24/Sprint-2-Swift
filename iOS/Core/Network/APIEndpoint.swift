//
//  APIEndpoint.swift
//  CampusMeal
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

// A relative endpoint under the shared `/api/v1/` base — e.g. "auth/login",
// "restaurants/search" — matching the paths documented in section 8 of
// `backend-architecture-and-frontend-integration.md`.
struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    var body: Encodable?
    var requiresAuth: Bool = true

    init(path: String, method: HTTPMethod, body: Encodable? = nil, requiresAuth: Bool = true) {
        self.path = path
        self.method = method
        self.body = body
        self.requiresAuth = requiresAuth
    }
}
