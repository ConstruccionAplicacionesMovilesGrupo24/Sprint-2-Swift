//
//  AnalyticsTracker.swift
//  CampusMeal
//

import Foundation

// Sends BQ8 recommendation events to `POST analytics/events` (202, empty body).
//
// - Fire-and-forget: tracking never blocks or breaks the UI; failures are dropped after
//   a couple of retries.
// - Idempotent: every event gets one `clientEventId` (UUID) that is reused on retries,
//   so the backend never stores it twice.
// - One impression per recommendation, even if the comparison screen re-appears.
// - Payloads never include coordinates, passwords or tokens (the bearer token travels only
//   in the Authorization header, set by APIClient).
//
// A plain class (main-actor isolated by the target's default isolation, like APIClient and
// SessionManager), so the impression set is only touched on the main actor.
final class AnalyticsTracker {
    static let shared = AnalyticsTracker()

    private let apiClient: APIClient
    private let maxAttempts: Int
    private var impressedRecommendationIds: Set<String> = []

    init(apiClient: APIClient = .shared, maxAttempts: Int = 3) {
        self.apiClient = apiClient
        self.maxAttempts = maxAttempts
    }

    func trackImpression(recommendationId: String) async {
        guard impressedRecommendationIds.insert(recommendationId).inserted else { return }
        await send(makeEvent(recommendationId: recommendationId, type: .recommendationImpression, selected: nil))
    }

    func trackSelection(recommendationId: String, alternative: String) async {
        await send(makeEvent(recommendationId: recommendationId, type: .recommendationSelected, selected: alternative))
    }

    private func makeEvent(recommendationId: String, type: AnalyticsEventType, selected: String?) -> AnalyticsEventRequest {
        AnalyticsEventRequest(
            clientEventId: UUID().uuidString.lowercased(),
            recommendationId: recommendationId,
            eventType: type,
            selectedAlternative: selected,
            platform: "IOS",
            occurredAt: ISO8601DateFormatter().string(from: .now)
        )
    }

    private func send(_ event: AnalyticsEventRequest) async {
        let endpoint = APIEndpoint(path: "analytics/events", method: .post, body: event)
        for attempt in 1...maxAttempts {
            do {
                try await apiClient.sendNoContent(endpoint)
                return
            } catch let error as APIError where !Self.isRetryable(error) {
                // 400/401/403/404: retrying the same payload cannot succeed.
                return
            } catch {
                guard attempt < maxAttempts else { return }
                try? await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
            }
        }
    }

    private static func isRetryable(_ error: APIError) -> Bool {
        switch error {
        case .transport, .server, .invalidResponse:
            true
        default:
            false
        }
    }
}
