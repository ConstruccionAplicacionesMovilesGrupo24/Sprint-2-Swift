//
//  SessionStore.swift
//  CampusMeal
//

import Foundation
import Security

// Abstraction over where the access/refresh token pair is persisted, so
// SessionManager can be tested with an in-memory fake instead of the real
// Keychain.
protocol SessionStore {
    func saveTokens(accessToken: String, refreshToken: String)
    func loadAccessToken() -> String?
    func loadRefreshToken() -> String?
    func clear()
}

// Stores tokens in the iOS Keychain (kSecClassGenericPassword), one item per
// token, scoped to this app via `service`. Tokens must never be persisted in
// UserDefaults or plain files per section 18 of
// backend-architecture-and-frontend-integration.md.
final class KeychainSessionStore: SessionStore {
    private let service = "com.campusmeal.session"
    private enum Account: String {
        case accessToken
        case refreshToken
    }

    func saveTokens(accessToken: String, refreshToken: String) {
        save(accessToken, for: .accessToken)
        save(refreshToken, for: .refreshToken)
    }

    func loadAccessToken() -> String? {
        load(.accessToken)
    }

    func loadRefreshToken() -> String? {
        load(.refreshToken)
    }

    func clear() {
        delete(.accessToken)
        delete(.refreshToken)
    }

    private func save(_ value: String, for account: Account) {
        let data = Data(value.utf8)
        let query = baseQuery(for: account)

        // Keychain has no "upsert" — try update first, add if the item
        // doesn't exist yet.
        let attributesToUpdate: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    private func load(_ account: Account) -> String? {
        var query = baseQuery(for: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func delete(_ account: Account) {
        SecItemDelete(baseQuery(for: account) as CFDictionary)
    }

    private func baseQuery(for account: Account) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account.rawValue
        ]
    }
}
