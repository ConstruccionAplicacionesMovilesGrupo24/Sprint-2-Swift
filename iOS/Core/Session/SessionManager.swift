//
//  SessionManager.swift
//  CampusMeal
//

import Foundation

// Wires KeychainSessionStore into APIClient (authorizationProvider +
// refreshHandler) and exposes login state for the UI. This is the only
// place that knows the shape of the `auth/refresh` contract — section 10 of
// backend-architecture-and-frontend-integration.md.
@Observable
final class SessionManager {
    static let shared = SessionManager()

    private let store: SessionStore
    private let apiClient: APIClient

    private(set) var isLoggedIn: Bool

    init(store: SessionStore = KeychainSessionStore(), apiClient: APIClient = .shared) {
        self.store = store
        self.apiClient = apiClient
        self.isLoggedIn = store.loadAccessToken() != nil

        apiClient.authorizationProvider = { [weak self] in self?.store.loadAccessToken() }
        apiClient.refreshHandler = { [weak self] in
            await self?.refreshSession() ?? false
        }
    }

    func completeLogin(accessToken: String, refreshToken: String) {
        store.saveTokens(accessToken: accessToken, refreshToken: refreshToken)
        isLoggedIn = true
    }

    func logout() {
        store.clear()
        isLoggedIn = false
    }

    private struct RefreshRequest: Encodable {
        let refreshToken: String
    }

    private struct RefreshResponse: Decodable {
        let accessToken: String
        let refreshToken: String
    }

    private func refreshSession() async -> Bool {
        guard let refreshToken = store.loadRefreshToken() else {
            logout()
            return false
        }

        do {
            let endpoint = APIEndpoint(
                path: "auth/refresh",
                method: .post,
                body: RefreshRequest(refreshToken: refreshToken),
                requiresAuth: false
            )
            let response: RefreshResponse = try await apiClient.send(endpoint)
            store.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
            return true
        } catch {
            logout()
            return false
        }
    }
}
