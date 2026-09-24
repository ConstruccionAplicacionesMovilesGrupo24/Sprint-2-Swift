//
//  DecisionRepository.swift
//  CampusMeal
//

import Foundation

// Talks to `POST meal-decisions/compare` (BQ5, CampusMealBack issue #6).
// Replaces the local rule-based `Recommender`: ranking now comes only from the backend.
struct DecisionRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func compare(_ request: CompareMealOptionsRequest) async throws -> CompareMealOptionsResponse {
        let endpoint = APIEndpoint(path: "meal-decisions/compare", method: .post, body: request)
        return try await apiClient.send(endpoint)
    }
}
