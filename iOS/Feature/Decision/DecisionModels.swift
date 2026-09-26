//
//  DecisionModels.swift
//  CampusMeal
//

import Foundation

// Field names match the backend contract exactly (CampusMealBack
// ISSUE_06_MEAL_DECISIONS.md, `POST meal-decisions/compare`, BQ5).
// The backend owns scores, ranking, the recommended alternative and the explanation;
// the app only displays them.

// MARK: - Request

struct MealDecisionLocation: Encodable {
    let latitude: Double
    let longitude: Double
}

struct CompareMealOptionsRequest: Encodable {
    let location: MealDecisionLocation
    let campusId: String?
    let availableMinutes: Int
    let maximumBudget: Int
    // VEGETARIAN | VEGAN | GLUTEN_FREE
    let dietaryPreferences: [String]
    let includeDelivery: Bool
    // ISO-8601 UTC instant ending in "Z".
    let requestedAt: String
}

// MARK: - Response

enum MealAlternativeType: String, Codable {
    case cook = "COOK"
    case walk = "WALK"
    case order = "ORDER"

    var title: String {
        switch self {
        case .cook: "Cook at home"
        case .walk: "Walk"
        case .order: "Order"
        }
    }

    var symbol: String {
        switch self {
        case .cook: "frying.pan"
        case .walk: "figure.walk"
        case .order: "takeoutbag.and.cup.and.straw"
        }
    }
}

struct ExpiringIngredientDTO: Decodable, Identifiable {
    let itemId: String
    let name: String
    let remainingDays: Int

    var id: String { itemId }
}

struct AlternativeRestaurantDTO: Decodable {
    let id: String
    let name: String
    // Null when the route provider is PARTIAL/UNAVAILABLE for this destination.
    let walkingMinutes: Int?
    let deliveryMinutes: Int?
    let deliveryFee: Int?
}

struct RecommendationAlternativeDTO: Decodable, Identifiable {
    let type: MealAlternativeType
    let rank: Int
    let score: Double
    let recommended: Bool
    let estimatedMinutes: Int
    // Whole COP.
    let estimatedCost: Int
    // COOK only.
    let expiringIngredients: [ExpiringIngredientDTO]?
    // WALK / ORDER only.
    let restaurant: AlternativeRestaurantDTO?

    var id: String { type.rawValue }
}

struct CompareMealOptionsResponse: Decodable {
    let recommendationId: String
    // Already in rank order; empty when no alternative fits right now.
    let alternatives: [RecommendationAlternativeDTO]
    let mainExplanation: String
    let supportingReasons: [String]
}
