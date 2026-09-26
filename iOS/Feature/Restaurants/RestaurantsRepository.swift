//
//  RestaurantsRepository.swift
//  CampusMeal
//

import Foundation

// Talks to `POST restaurants/search` and `GET restaurants/:id`
// (BQ4, CampusMealBack issue #5). Auth header and 401 refresh are handled by APIClient.
struct RestaurantsRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func search(_ request: RestaurantSearchRequest) async throws -> RestaurantSearchResponse {
        let endpoint = APIEndpoint(path: "restaurants/search", method: .post, body: request)
        return try await apiClient.send(endpoint)
    }

    func fetchDetail(restaurantId: String) async throws -> RestaurantDetailResponse {
        let endpoint = APIEndpoint(path: "restaurants/\(restaurantId)", method: .get)
        return try await apiClient.send(endpoint)
    }
}
