//
//  ComparisonView.swift
//  CampusMeal
//
//  Created by Carlos Poveda on 18/9/26.
//

import SwiftUI

// MARK: - Mock domain (MS7 prototype data — Sprint 2 will replace this with a real
// repository backed by the CampusMeal API and the shared Inventory feature).

private enum MealMode: String, CaseIterable, Identifiable {
    case cook = "Cook", walk = "Walk", order = "Order"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .cook: "frying.pan"
        case .walk: "figure.walk"
        case .order: "takeoutbag.and.cup.and.straw"
        }
    }
}

private struct MealOption: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let mode: MealMode
    let price: Int
    let minutes: Int
    var ingredientTags: [String] = []
}

private struct InventoryItem: Identifiable {
    let id: String
    let name: String
    let daysUntilExpiration: Int

    var isExpiringSoon: Bool { daysUntilExpiration <= 3 }
}

private func cop(_ amount: Int) -> String {
    amount.formatted(.currency(code: "COP").precision(.fractionLength(0)))
}

// Demonstration data only; matches the ingredients referenced in the Home
// screen's "Expiring soon" list (Figma frame 05), so the two screens stay consistent.
private let mockInventory: [InventoryItem] = [
    InventoryItem(id: "milk", name: "Whole milk", daysUntilExpiration: 0),
    InventoryItem(id: "tomatoes", name: "Tomatoes", daysUntilExpiration: 2)
]

private let mockOptions: [MealOption] = [
    MealOption(id: "cook-pasta", title: "Creamy tomato pasta", subtitle: "sample recipe",
               mode: .cook, price: 4500, minutes: 15, ingredientTags: ["milk", "tomatoes"]),
    MealOption(id: "cook-bowl", title: "Vegetable rice bowl", subtitle: "sample recipe",
               mode: .cook, price: 8000, minutes: 25, ingredientTags: ["tomatoes"]),
    MealOption(id: "walk-green-bowl", title: "Green Bowl", subtitle: "12 min walk",
               mode: .walk, price: 17000, minutes: 38),
    MealOption(id: "walk-fresh-fields", title: "Fresh Fields", subtitle: "9 min walk",
               mode: .walk, price: 19000, minutes: 30),
    MealOption(id: "order-la-huerta", title: "La Huerta", subtitle: "delivery",
               mode: .order, price: 23500, minutes: 45)
]

// MARK: - Recommender

/// Simple, transparent heuristic used to rank meal options — rule-based logic
/// over budget, time and pantry data, not a trained model (see MS7 §1).
private enum Recommender {
    static func score(for option: MealOption, budget: Double, availableMinutes: Double, inventory: [InventoryItem]) -> Int {
        let budgetFit = budget > 0 ? max(0, min(1, (budget - Double(option.price)) / budget)) : 0
        let timeFit = availableMinutes > 0 ? max(0, min(1, (availableMinutes - Double(option.minutes)) / availableMinutes)) : 0

        var ingredientBonus = 0.0
        if option.mode == .cook {
            let expiringSoonIDs = Set(inventory.filter(\.isExpiringSoon).map(\.id))
            let matches = option.ingredientTags.filter { expiringSoonIDs.contains($0) }.count
            ingredientBonus = Double(matches) * 15
        }

        let raw = budgetFit * 40 + timeFit * 40 + ingredientBonus
        return min(max(Int(raw.rounded()), 0), 100)
    }

    static func confidenceLabel(forScore score: Int) -> String {
        switch score {
        case 85...: "High"
        case 60..<85: "Medium"
        default: "Low"
        }
    }
}

private struct RankedOption: Identifiable {
    let option: MealOption
    let score: Int
    var id: String { option.id }
}

// MARK: - Comparison screen (Figma frame 11)

struct ComparisonView: View {
    @Environment(\.dismiss) private var dismiss

    // Mock context — Sprint 2 will read this from the shared Context feature
    // once Navigation wires the screens together.
    private let budget: Double = 20000
    private let availableMinutes: Double = 45
    private let dietaryPreference = "Vegetarian"

    private var ranked: [RankedOption] {
        Dictionary(grouping: mockOptions, by: \.mode)
            .compactMap { _, options -> RankedOption? in
                options
                    .map { RankedOption(option: $0, score: Recommender.score(for: $0, budget: budget, availableMinutes: availableMinutes, inventory: mockInventory)) }
                    .max { $0.score < $1.score }
            }
            .sorted { $0.score > $1.score }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Label("Visual prototype · sample data", systemImage: "info.circle")
                    .font(CampusMealTypography.caption)
                    .foregroundStyle(CampusMealColors.neutral500)

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

                Text("\(Int(availableMinutes)) min available · \(cop(Int(budget))) · \(dietaryPreference)")
                    .font(CampusMealTypography.bodyS)
                    .foregroundStyle(CampusMealColors.neutral500)

                ForEach(Array(ranked.enumerated()), id: \.element.id) { index, entry in
                    if index == 0 {
                        RecommendedCard(ranked: entry, budget: budget, availableMinutes: availableMinutes, inventory: mockInventory)
                    } else {
                        AlternativeCard(ranked: entry, budget: budget, availableMinutes: availableMinutes)
                    }
                }

                Text("Prices and times are illustrative. This prototype does not place orders.")
                    .font(CampusMealTypography.caption)
                    .foregroundStyle(CampusMealColors.neutral500)
            }
            .padding()
        }
        .background(CampusMealColors.neutral50)
        .toolbar(.hidden, for: .navigationBar)
    }
}

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

private struct RecommendedCard: View {
    let ranked: RankedOption
    let budget: Double
    let availableMinutes: Double
    let inventory: [InventoryItem]

    private var option: MealOption { ranked.option }

    private var matchedIngredients: [InventoryItem] {
        inventory.filter { option.ingredientTags.contains($0.id) && $0.isExpiringSoon }
    }

    private var timeBuffer: Int { Int(availableMinutes) - option.minutes }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("RECOMMENDED")
                    .font(CampusMealTypography.labelS)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(CampusMealColors.brand500, in: Capsule())
                    .foregroundStyle(CampusMealColors.neutral0)
                Spacer()
                Image(systemName: option.mode.symbol)
                    .foregroundStyle(CampusMealColors.brand500)
            }
            HStack(alignment: .firstTextBaseline) {
                Text(option.mode == .cook ? "Cook at home" : option.mode.rawValue)
                    .font(CampusMealTypography.headingXL)
                    .foregroundStyle(CampusMealColors.neutral900)
                Spacer()
                Text("\(ranked.score)")
                    .font(CampusMealTypography.displayL)
                    .foregroundStyle(CampusMealColors.brand500)
            }

            HStack(spacing: 10) {
                MetricChip(value: "\(option.minutes) min", label: option.mode == .cook ? "Prep time" : "Total")
                MetricChip(value: cop(option.price), label: option.mode == .cook ? "Estimated cost" : "Cost")
                MetricChip(value: Recommender.confidenceLabel(forScore: ranked.score), label: "Confidence")
            }

            if option.mode == .cook && !matchedIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Why?")
                        .font(CampusMealTypography.headingM)
                        .foregroundStyle(CampusMealColors.neutral900)
                    let names = matchedIngredients.map { $0.name.lowercased() }.joined(separator: " and ")
                    Text("Uses \(matchedIngredients.count == 1 ? "one ingredient" : "\(matchedIngredients.count) ingredients") expiring soon: \(names).")
                        .font(CampusMealTypography.bodyM)
                        .foregroundStyle(CampusMealColors.neutral700)
                    if timeBuffer > 0 {
                        Text("· Fits your available time with a \(timeBuffer) min buffer")
                            .font(CampusMealTypography.bodyM)
                            .foregroundStyle(CampusMealColors.neutral700)
                    }
                }
            }

            HStack(spacing: 12) {
                Button {
                    // Recipe detail — implemented alongside BQ work in Sprint 2.
                } label: {
                    Text("View recipe")
                        .font(CampusMealTypography.labelL)
                        .foregroundStyle(CampusMealColors.brand600)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(CampusMealColors.brand500, lineWidth: 1.5))
                }
                Button {
                    // Choosing an option — implemented alongside Decision persistence in Sprint 2.
                } label: {
                    Text("Choose")
                        .font(CampusMealTypography.labelL)
                        .foregroundStyle(CampusMealColors.neutral900)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(CampusMealColors.brand500, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .background(CampusMealColors.brand50, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(CampusMealColors.brand500, lineWidth: 1.5))
    }
}

private struct AlternativeCard: View {
    let ranked: RankedOption
    let budget: Double
    let availableMinutes: Double
    private var option: MealOption { ranked.option }

    private var fitsCaption: String {
        option.price <= Int(budget) && option.minutes <= Int(availableMinutes)
            ? "Within your budget and time."
            : "Outside your current budget or time."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(option.mode.rawValue)
                    .font(CampusMealTypography.headingM)
                    .foregroundStyle(CampusMealColors.neutral900)
                Spacer()
                Image(systemName: option.mode.symbol)
                    .foregroundStyle(CampusMealColors.brand500)
            }
            Text("\(option.title) · \(option.subtitle)")
                .font(CampusMealTypography.bodyS)
                .foregroundStyle(CampusMealColors.neutral500)
            HStack(spacing: 10) {
                MetricChip(value: "\(option.minutes) min", label: "Total", tint: CampusMealColors.sand100)
                MetricChip(value: cop(option.price), label: "Cost", tint: CampusMealColors.sand100)
                MetricChip(value: "\(ranked.score)", label: "Score", tint: CampusMealColors.sand100)
            }
            Text(fitsCaption)
                .font(CampusMealTypography.bodyS)
                .foregroundStyle(CampusMealColors.neutral500)
        }
        .padding()
        .background(CampusMealColors.neutral0, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    ComparisonView()
}
