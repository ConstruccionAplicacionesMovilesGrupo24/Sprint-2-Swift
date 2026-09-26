//
//  AuthRepository.swift
//  CampusMeal
//

import Foundation

// Talks to `POST auth/register` and `POST auth/login`
// (backend-architecture-and-frontend-integration.md §10). On success, hands the
// token pair to SessionManager, which owns Keychain storage — this repository
// never touches Keychain directly. `logout()` delegates entirely to
// SessionManager.endSession(), which already knows the auth/logout contract.
struct AuthRepository {
    private let apiClient: APIClient
    private let sessionManager: SessionManager

    init(apiClient: APIClient = .shared, sessionManager: SessionManager = .shared) {
        self.apiClient = apiClient
        self.sessionManager = sessionManager
    }

    func register(fullName: String, email: String, password: String) async throws {
        let endpoint = APIEndpoint(
            path: "auth/register",
            method: .post,
            body: RegisterRequest(fullName: fullName, email: email, password: password),
            requiresAuth: false
        )
        let tokens: AuthTokensResponse = try await apiClient.send(endpoint)
        sessionManager.completeLogin(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
    }

    func login(email: String, password: String) async throws {
        let endpoint = APIEndpoint(
            path: "auth/login",
            method: .post,
            body: LoginRequest(email: email, password: password),
            requiresAuth: false
        )
        let tokens: AuthTokensResponse = try await apiClient.send(endpoint)
        sessionManager.completeLogin(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
    }

    func logout() async {
        await sessionManager.endSession()
    }
}
