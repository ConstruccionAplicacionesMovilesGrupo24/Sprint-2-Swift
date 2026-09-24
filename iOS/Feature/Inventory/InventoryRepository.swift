//
//  InventoryRepository.swift
//  CampusMeal
//

import Foundation

// Talks to `GET inventory/expiring?withinDays=N` (BQ2, CampusMealBack issue #3).
// Auth header and 401 refresh are handled by APIClient/SessionManager.
struct InventoryRepository {
    static let defaultWithinDays = 3

    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func fetchExpiringItems(withinDays: Int = defaultWithinDays) async throws -> [InventoryItemDTO] {
        let endpoint = APIEndpoint(
            path: "inventory/expiring",
            method: .get,
            queryItems: [URLQueryItem(name: "withinDays", value: String(withinDays))]
        )
        let response: ExpiringInventoryResponse = try await apiClient.send(endpoint)
        return response.items
    }
}
