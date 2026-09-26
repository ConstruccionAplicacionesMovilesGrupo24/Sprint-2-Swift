//
//  RestaurantsModels.swift
//  CampusMeal
//

import Foundation

// Field names match the backend contract exactly (CampusMealBack docs/API_CONTRACT.md §8,
// ISSUE_05_CONTEXT_AWARE_SEARCH.md). Money is whole COP as Int.

// MARK: - Request (POST restaurants/search)

struct GeoLocation: Encodable {
    let latitude: Double
    let longitude: Double
}

enum DietaryTag: String, Codable, CaseIterable {
    case vegetarian = "VEGETARIAN"
    case vegan = "VEGAN"
    case glutenFree = "GLUTEN_FREE"

    var label: String {
        switch self {
        case .vegetarian: "Vegetarian"
        case .vegan: "Vegan"
        case .glutenFree: "Gluten-free"
        }
    }
}

struct RestaurantSearchRequest: Encodable {
    let location: GeoLocation
    let campusId: String?
    let availableMinutes: Int
    let maximumBudget: Int
    let dietaryPreferences: [DietaryTag]
    let includeDelivery: Bool
    // ISO-8601 UTC instant ending in "Z" (the backend rejects offsets).
    let requestedAt: String
}

// MARK: - Response

// Unknown values fall back to `.unknown` so a new backend value never breaks decoding.
enum OpeningStatus: String, Decodable {
    case open = "OPEN"
    case closingSoon = "CLOSING_SOON"
    case closed = "CLOSED"
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = OpeningStatus(rawValue: raw) ?? .unknown
    }
}

enum RouteProviderStatus: String, Decodable {
    case available = "AVAILABLE"
    case partial = "PARTIAL"
    case unavailable = "UNAVAILABLE"
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = RouteProviderStatus(rawValue: raw) ?? .unknown
    }
}

struct RestaurantDTO: Decodable, Identifiable {
    let id: String
    let name: String
    let category: String
    let openingStatus: OpeningStatus
    // Null when the route provider couldn't estimate this destination (PARTIAL/UNAVAILABLE).
    let walkingMinutes: Int?
    let estimatedTotalMinutes: Int?
    let minimumMealPrice: Int
    let dietaryTags: [DietaryTag]
    let averageRating: Double
    let recommendationReason: String
}

struct RestaurantSearchResponse: Decodable {
    let restaurants: [RestaurantDTO]
    // Kept as String: the backend emits fractional seconds ("…45:30.519Z"), which
    // JSONDecoder's `.iso8601` strategy does not accept.
    let lastUpdatedAt: String
    let routeProviderStatus: RouteProviderStatus
}

struct MealDTO: Decodable, Identifiable {
    let id: String
    let name: String
    let price: Int
    let dietaryTags: [DietaryTag]
}

struct RestaurantDetailResponse: Decodable {
    let restaurant: RestaurantDTO
    let address: String
    let meals: [MealDTO]
    let lastUpdatedAt: String
    let routeProviderStatus: RouteProviderStatus
}

// MARK: - Formatting helpers

enum CampusMealFormat {
    // "$14,500" — whole COP.
    static func cop(_ amount: Int) -> String {
        "$" + amount.formatted(.number.grouping(.automatic).locale(Locale(identifier: "en_US")))
    }

    // Parses backend instants with or without fractional seconds.
    static func instant(_ value: String) -> Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return withFraction.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }

    // Always UTC with a "Z" suffix and no fractional seconds, as the backend requires.
    static func utcTimestamp(_ date: Date = .now) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
