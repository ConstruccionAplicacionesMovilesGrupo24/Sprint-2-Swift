//
//  RestaurantsView.swift
//  CampusMeal
//
//  Created by Daniel Vargas on 17/9/26.
//

import SwiftUI

private enum RestaurantStatus {
    case openNow
    case opensAt(String)
    case closed
}

private struct Restaurant: Identifiable {
    let id = UUID()
    let name: String
    let tags: String
    let rating: Double
    let walkMinutes: Int
    let totalMinutes: Int?
    let priceFrom: String
    let status: RestaurantStatus
    let recommendation: String?
    let updatedLabel: String
}

// Mock data for MS7 — will be replaced by a real repository backed by the CampusMeal API in Sprint 2.
private let mockRestaurants: [Restaurant] = [
    Restaurant(name: "Green Bowl", tags: "Healthy · Bowls", rating: 4.6, walkMinutes: 12, totalMinutes: 38, priceFrom: "$17,000", status: .openNow, recommendation: "Recommended because it fits your 45 minutes and your budget.", updatedLabel: "Updated today"),
    Restaurant(name: "The Garden", tags: "Home-style", rating: 4.4, walkMinutes: 8, totalMinutes: 31, priceFrom: "$14,500", status: .openNow, recommendation: "The fastest option with today's vegetarian menu.", updatedLabel: "Updated today"),
    Restaurant(name: "Andean Flavor", tags: "Business lunches", rating: 4.2, walkMinutes: 15, totalMinutes: nil, priceFrom: "$16,000", status: .opensAt("5:00 PM"), recommendation: nil, updatedLabel: "Updated today"),
    Restaurant(name: "Sushi Rápido", tags: "Japanese", rating: 4.2, walkMinutes: 7, totalMinutes: 24, priceFrom: "$22,000", status: .openNow, recommendation: nil, updatedLabel: "Updated yesterday")
]

struct RestaurantsView: View {
    var body: some View {
        ZStack {
            CampusMealColors.neutral50
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(CampusMealColors.neutral900)

                    Text("Nearby restaurants")
                        .font(CampusMealTypography.headingL)
                        .foregroundStyle(CampusMealColors.neutral900)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                HStack {
                    Text("45 min · COP 20,000 · Vegetarian")
                        .font(CampusMealTypography.bodyM)
                        .foregroundStyle(CampusMealColors.brand700)

                    Spacer()

                    Text("Filters")
                        .font(CampusMealTypography.labelM)
                        .foregroundStyle(CampusMealColors.brand600)
                }
                .padding(14)
                .background(CampusMealColors.brand100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(mockRestaurants) { restaurant in
                            RestaurantCard(restaurant: restaurant)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

private struct RestaurantCard: View {
    let restaurant: Restaurant

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(restaurant.name)
                    .font(CampusMealTypography.headingM)
                    .foregroundStyle(CampusMealColors.neutral900)

                Spacer()

                StatusPill(status: restaurant.status)
            }

            Text("\(restaurant.tags) · ★ \(String(format: "%.1f", restaurant.rating))")
                .font(CampusMealTypography.bodyS)
                .foregroundStyle(CampusMealColors.neutral500)

            HStack(spacing: 10) {
                StatChip(value: "\(restaurant.walkMinutes) min", label: "Walk")
                StatChip(value: restaurant.totalMinutes.map { "\($0) min" } ?? "—", label: "Total")
                StatChip(value: restaurant.priceFrom, label: "From")
            }

            if let recommendation = restaurant.recommendation {
                Text(recommendation)
                    .font(CampusMealTypography.bodyS)
                    .foregroundStyle(CampusMealColors.neutral700)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CampusMealColors.accent50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            HStack {
                Text(restaurant.updatedLabel)
                    .font(CampusMealTypography.caption)
                    .foregroundStyle(CampusMealColors.neutral500)

                Spacer()

                Button {
                    // Navigation to restaurant detail — implemented alongside BQ work in Sprint 2.
                } label: {
                    Text("View details")
                        .font(CampusMealTypography.labelM)
                        .foregroundStyle(CampusMealColors.brand600)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(CampusMealColors.brand500, lineWidth: 1.5)
                        )
                }
            }
        }
        .padding(14)
        .background(CampusMealColors.neutral0)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct StatChip: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(CampusMealTypography.labelL)
                .foregroundStyle(CampusMealColors.neutral900)
            Text(label)
                .font(CampusMealTypography.caption)
                .foregroundStyle(CampusMealColors.neutral500)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(CampusMealColors.sand100)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct StatusPill: View {
    let status: RestaurantStatus

    private var text: String {
        switch status {
        case .openNow: "Open now"
        case .opensAt(let time): "Opens \(time)"
        case .closed: "Closed"
        }
    }

    private var foreground: Color {
        switch status {
        case .openNow: CampusMealColors.positive700
        case .opensAt, .closed: CampusMealColors.neutral700
        }
    }

    private var background: Color {
        switch status {
        case .openNow: CampusMealColors.positive100
        case .opensAt, .closed: CampusMealColors.neutral100
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            if case .openNow = status {
                Circle()
                    .fill(CampusMealColors.positive500)
                    .frame(width: 6, height: 6)
            } else if case .opensAt = status {
                Image(systemName: "clock")
                    .font(.system(size: 10))
            }
            Text(text)
                .font(CampusMealTypography.caption)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(background)
        .clipShape(Capsule())
    }
}

#Preview {
    RestaurantsView()
}
