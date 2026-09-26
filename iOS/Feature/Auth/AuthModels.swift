//
//  AuthModels.swift
//  CampusMeal
//

import Foundation

// Field names match the backend contract exactly (backend docs/API_CONTRACT.md §5,
// and ISSUE_02_AUTHENTICATION.md's Android-compatibility note: registration uses
// `fullName`, not `name`).

struct RegisterRequest: Encodable {
    let fullName: String
    let email: String
    let password: String
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct AuthTokensResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}
