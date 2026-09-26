//
//  AnalyticsModels.swift
//  CampusMeal
//

import Foundation

// Body of `POST analytics/events` (CampusMealBack issue #7, API_CONTRACT §10).
// Deliberately contains no coordinates, tokens, passwords or explanation category —
// the backend derives the explanation from the stored recommendation (BQ8).

enum AnalyticsEventType: String, Encodable {
    case recommendationImpression = "RECOMMENDATION_IMPRESSION"
    case recommendationSelected = "RECOMMENDATION_SELECTED"
}

struct AnalyticsEventRequest: Encodable, Equatable {
    // Generated once per event and reused on retries, so the backend stores it only once.
    let clientEventId: String
    let recommendationId: String
    let eventType: AnalyticsEventType
    // "COOK" | "WALK" | "ORDER" for selections; null for impressions.
    let selectedAlternative: String?
    let platform: String
    // ISO-8601 UTC instant ending in "Z".
    let occurredAt: String

    // Encodes `selectedAlternative: null` explicitly (synthesized Encodable would omit it),
    // matching the contract examples exactly.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(clientEventId, forKey: .clientEventId)
        try container.encode(recommendationId, forKey: .recommendationId)
        try container.encode(eventType, forKey: .eventType)
        try container.encode(selectedAlternative, forKey: .selectedAlternative)
        try container.encode(platform, forKey: .platform)
        try container.encode(occurredAt, forKey: .occurredAt)
    }

    private enum CodingKeys: String, CodingKey {
        case clientEventId, recommendationId, eventType, selectedAlternative, platform, occurredAt
    }
}
