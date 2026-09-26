//
//  ContextModels.swift
//  CampusMeal
//

import Foundation

// Only one campus exists in the seeded backend data (Universidad de los Andes) — this is a
// single-campus app for Sprint 2, not a placeholder for a picker with nothing to pick.
enum CampusOption: String, CaseIterable, Identifiable {
    case uniandes = "campus-001"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .uniandes: "Universidad de los Andes"
        }
    }

    var coordinates: Coordinates {
        switch self {
        case .uniandes: Coordinates(latitude: 4.6025, longitude: -74.0653)
        }
    }
}

/// The shared search/decision context BQ4 and BQ5 both need. A single instance lives in
/// `ContextStore` so Home, Restaurants and Decision always agree on it.
struct MealContext {
    enum LocationSource: Equatable {
        case device(Coordinates)
        case manualCampus(CampusOption)
    }

    var locationSource: LocationSource = .manualCampus(.uniandes)
    var availableMinutes = 45
    var maximumBudget = 20_000
    var dietaryPreferences: [DietaryTag] = [.vegetarian]
    var includeDelivery = true

    var coordinates: Coordinates {
        switch locationSource {
        case .device(let coordinates): coordinates
        case .manualCampus(let campus): campus.coordinates
        }
    }

    // nil for device location: the backend treats a missing campusId as "use the coordinates".
    var campusId: String? {
        switch locationSource {
        case .device: nil
        case .manualCampus(let campus): campus.rawValue
        }
    }

    var campusDisplayName: String {
        switch locationSource {
        case .device: "Current location"
        case .manualCampus(let campus): campus.displayName
        }
    }

    var summary: String {
        let diet = dietaryPreferences.map(\.label).joined(separator: ", ")
        return "\(availableMinutes) min · \(CampusMealFormat.cop(maximumBudget))"
            + (diet.isEmpty ? "" : " · \(diet)")
    }
}

// MARK: - Request builders

// Kept here (rather than on RestaurantsView/ComparisonView) because Context is the one place
// that knows how to turn a MealContext into each endpoint's request shape.
extension MealContext {
    func restaurantSearchRequest(at date: Date = .now) -> RestaurantSearchRequest {
        RestaurantSearchRequest(
            location: GeoLocation(latitude: coordinates.latitude, longitude: coordinates.longitude),
            campusId: campusId,
            availableMinutes: availableMinutes,
            maximumBudget: maximumBudget,
            dietaryPreferences: dietaryPreferences,
            includeDelivery: includeDelivery,
            requestedAt: CampusMealFormat.utcTimestamp(date)
        )
    }

    func compareMealOptionsRequest(at date: Date = .now) -> CompareMealOptionsRequest {
        CompareMealOptionsRequest(
            location: MealDecisionLocation(latitude: coordinates.latitude, longitude: coordinates.longitude),
            campusId: campusId,
            availableMinutes: availableMinutes,
            maximumBudget: maximumBudget,
            dietaryPreferences: dietaryPreferences.map(\.rawValue),
            includeDelivery: includeDelivery,
            // ISO8601DateFormatter emits UTC with a "Z" and no fractional seconds.
            requestedAt: ISO8601DateFormatter().string(from: date)
        )
    }
}
