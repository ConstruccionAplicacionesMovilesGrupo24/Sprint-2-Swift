//
//  ComparisonView.swift
//  CampusMeal
//
//  Created by Carlos Poveda on 18/9/26.
//

import SwiftUI

// MARK: - Comparison context

// Context sent to BQ5. The Context feature and Core/Location are not built yet, so this uses
// the manual-campus fallback (Uniandes) and the same sample values shown on Home.
struct DecisionContext {
    var latitude = 4.6025
    var longitude = -74.0653
    var campusId: String? = "campus-001"
    var availableMinutes = 45
    var maximumBudget = 20_000
    var dietaryPreferences: [String] = ["VEGETARIAN"]
    var includeDelivery = true

    var summary: String {
        let diet = dietaryPreferences.map { $0.replacingOccurrences(of: "_", with: "-").capitalized }
        return (["\(availableMinutes) min available", cop(maximumBudget)] + diet).joined(separator: " · ")
    }

    func request(at date: Date = .now) -> CompareMealOptionsRequest {
        CompareMealOptionsRequest(
            location: MealDecisionLocation(latitude: latitude, longitude: longitude),
            campusId: campusId,
            availableMinutes: availableMinutes,
            maximumBudget: maximumBudget,
            dietaryPreferences: dietaryPreferences,
            includeDelivery: includeDelivery,
            // ISO8601DateFormatter emits UTC with a "Z" and no fractional seconds.
            requestedAt: ISO8601DateFormatter().string(from: date)
        )
    }
}

private func cop(_ amount: Int) -> String {
    amount.formatted(.currency(code: "COP").precision(.fractionLength(0)))
}

private enum ComparisonState {
    case loading
    case loaded(CompareMealOptionsResponse)
    case failed(String)
}

// MARK: - Comparison screen (Figma frame 11)

// Displays the backend's BQ5 result as-is: order, rank, score, recommended flag and
// explanation all come from `POST meal-decisions/compare`. No ranking happens on the client.
struct ComparisonView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var state: ComparisonState = .loading
    @State private var selectedType: MealAlternativeType?

    var context = DecisionContext()
    private let repository = DecisionRepository()
    private let analytics = AnalyticsTracker.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(CampusMealColors.neutral900)
                    }
                    Text("Cook, walk, or order")
                        .font(CampusMealTypography.headingXL)
                        .lineSpacing(CampusMealTypography.LineSpacing.headingXL)
                        .foregroundStyle(CampusMealColors.neutral900)
                }

                Text(context.summary)
                    .font(CampusMealTypography.bodyS)
                    .foregroundStyle(CampusMealColors.neutral500)

                content

                Text("Scores and explanations come from CampusMeal's recommendation service. This app does not place orders.")
                    .font(CampusMealTypography.caption)
                    .foregroundStyle(CampusMealColors.neutral500)
            }
            .padding()
        }
        .background(CampusMealColors.neutral50)
        .toolbar(.hidden, for: .navigationBar)
        .task { await compare() }
        .refreshable { await compare() }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        case .failed(let message):
            VStack(alignment: .leading, spacing: 8) {
                // No "negative/error" color in the design system yet — same choice as LoginView.
                Text(message)
                    .font(CampusMealTypography.bodyM)
                    .foregroundStyle(.red)
                Button("Try again") { Task { await compare() } }
                    .font(CampusMealTypography.labelM)
                    .foregroundStyle(CampusMealColors.brand600)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CampusMealColors.neutral0, in: RoundedRectangle(cornerRadius: 20))
        case .loaded(let response) where response.alternatives.isEmpty:
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.system(size: 28))
                    .foregroundStyle(CampusMealColors.neutral500)
                Text(response.mainExplanation)
                    .font(CampusMealTypography.bodyM)
                    .foregroundStyle(CampusMealColors.neutral700)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CampusMealColors.neutral0, in: RoundedRectangle(cornerRadius: 20))
        case .loaded(let response):
            ForEach(response.alternatives) { alternative in
                if alternative.recommended {
                    RecommendedCard(
                        alternative: alternative,
                        mainExplanation: response.mainExplanation,
                        supportingReasons: response.supportingReasons,
                        isSelected: selectedType == alternative.type,
                        onChoose: { choose(alternative) }
                    )
                } else {
                    AlternativeCard(
                        alternative: alternative,
                        isSelected: selectedType == alternative.type,
                        onChoose: { choose(alternative) }
                    )
                }
            }
        }
    }

    private func compare() async {
        if case .loaded = state {} else { state = .loading }
        do {
            let response = try await repository.compare(context.request())
            selectedType = nil
            state = .loaded(response)
            // BQ8: the result is now on screen. Only results with alternatives can be selected.
            if !response.alternatives.isEmpty {
                Task { await analytics.trackImpression(recommendationId: response.recommendationId) }
            }
        } catch APIError.unauthorized {
            state = .failed("Your session expired. Please log in again.")
        } catch {
            state = .failed("Couldn't compare your options. Check your connection and try again.")
        }
    }

    private func choose(_ alternative: RecommendationAlternativeDTO) {
        guard case .loaded(let response) = state, selectedType != alternative.type else { return }
        selectedType = alternative.type
        // BQ8: only the recommendation id and the chosen type are sent — the backend derives
        // the explanation category itself.
        Task {
            await analytics.trackSelection(
                recommendationId: response.recommendationId,
                alternative: alternative.type.rawValue
            )
        }
    }
}

// MARK: - Cards

private struct MetricChip: View {
    let value: String
    let label: String
    var tint: Color = CampusMealColors.neutral0

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(CampusMealTypography.headingM)
                .foregroundStyle(CampusMealColors.neutral900)
            Text(label)
                .font(CampusMealTypography.caption)
                .foregroundStyle(CampusMealColors.neutral500)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(tint, in: RoundedRectangle(cornerRadius: 12))
    }
}

private extension RecommendationAlternativeDTO {
    var displayScore: String { "\(Int(score.rounded()))" }

    // "Green Bowl · 12 min walk", "Green Bowl · delivery", "Uses 3 expiring items".
    var subtitle: String {
        switch type {
        case .cook:
            let count = expiringIngredients?.count ?? 0
            return count == 0 ? "With what you have at home" : "Uses \(count) item\(count == 1 ? "" : "s") expiring soon"
        case .walk:
            let name = restaurant?.name ?? "Nearby restaurant"
            // walkingMinutes is null when the route provider couldn't estimate it.
            return restaurant?.walkingMinutes.map { "\(name) · \($0) min walk" } ?? "\(name) · walking time unavailable"
        case .order:
            return "\(restaurant?.name ?? "Restaurant") · delivery"
        }
    }
}

private struct ChooseButton: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(isSelected ? "Chosen" : "Choose", systemImage: isSelected ? "checkmark" : "hand.tap")
                .font(CampusMealTypography.labelL)
                .foregroundStyle(CampusMealColors.neutral900)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(CampusMealColors.brand500, in: RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isSelected)
    }
}

private struct RecommendedCard: View {
    let alternative: RecommendationAlternativeDTO
    let mainExplanation: String
    let supportingReasons: [String]
    let isSelected: Bool
    let onChoose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("RECOMMENDED")
                    .font(CampusMealTypography.labelS)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(CampusMealColors.brand500, in: Capsule())
                    .foregroundStyle(CampusMealColors.neutral0)
                Spacer()
                Image(systemName: alternative.type.symbol)
                    .foregroundStyle(CampusMealColors.brand500)
            }
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(alternative.type.title)
                        .font(CampusMealTypography.headingXL)
                        .foregroundStyle(CampusMealColors.neutral900)
                    Text(alternative.subtitle)
                        .font(CampusMealTypography.bodyS)
                        .foregroundStyle(CampusMealColors.neutral500)
                }
                Spacer()
                Text(alternative.displayScore)
                    .font(CampusMealTypography.displayL)
                    .foregroundStyle(CampusMealColors.brand500)
            }

            HStack(spacing: 10) {
                MetricChip(value: "\(alternative.estimatedMinutes) min", label: alternative.type == .cook ? "Prep time" : "Total")
                MetricChip(value: cop(alternative.estimatedCost), label: alternative.type == .cook ? "Estimated cost" : "Cost")
                MetricChip(value: "#\(alternative.rank)", label: "Rank")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Why?")
                    .font(CampusMealTypography.headingM)
                    .foregroundStyle(CampusMealColors.neutral900)
                Text(mainExplanation)
                    .font(CampusMealTypography.bodyM)
                    .foregroundStyle(CampusMealColors.neutral700)
                ForEach(supportingReasons, id: \.self) { reason in
                    Text("· \(reason)")
                        .font(CampusMealTypography.bodyM)
                        .foregroundStyle(CampusMealColors.neutral700)
                }
                if let ingredients = alternative.expiringIngredients, !ingredients.isEmpty {
                    Text("Expiring: " + ingredients.map { $0.name.lowercased() }.joined(separator: ", "))
                        .font(CampusMealTypography.bodyS)
                        .foregroundStyle(CampusMealColors.neutral500)
                }
            }

            ChooseButton(isSelected: isSelected, action: onChoose)
        }
        .padding()
        .background(CampusMealColors.brand50, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(CampusMealColors.brand500, lineWidth: 1.5))
    }
}

private struct AlternativeCard: View {
    let alternative: RecommendationAlternativeDTO
    let isSelected: Bool
    let onChoose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(alternative.type.title)
                    .font(CampusMealTypography.headingM)
                    .foregroundStyle(CampusMealColors.neutral900)
                Spacer()
                Image(systemName: alternative.type.symbol)
                    .foregroundStyle(CampusMealColors.brand500)
            }
            Text(alternative.subtitle)
                .font(CampusMealTypography.bodyS)
                .foregroundStyle(CampusMealColors.neutral500)
            HStack(spacing: 10) {
                MetricChip(value: "\(alternative.estimatedMinutes) min", label: "Total", tint: CampusMealColors.sand100)
                MetricChip(value: cop(alternative.estimatedCost), label: "Cost", tint: CampusMealColors.sand100)
                MetricChip(value: alternative.displayScore, label: "Score", tint: CampusMealColors.sand100)
            }
            ChooseButton(isSelected: isSelected, action: onChoose)
        }
        .padding()
        .background(CampusMealColors.neutral0, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    ComparisonView()
}
