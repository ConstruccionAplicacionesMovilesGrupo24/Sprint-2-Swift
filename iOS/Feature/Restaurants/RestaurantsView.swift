//
//  RestaurantsView.swift
//  CampusMeal
//
//  Created by Daniel Vargas on 17/9/26.
//

import SwiftUI

private struct Restaurant: Identifiable {
    let id = UUID()
    let name: String
    let cuisine: String
    let distanceMinutes: Int
    let rating: Double
    let isOpen: Bool
}

// Mock data for MS7 — will be replaced by a real repository backed by the CampusMeal API in Sprint 2.
private let mockRestaurants: [Restaurant] = [
    Restaurant(name: "La Central Uniandina", cuisine: "Colombian", distanceMinutes: 4, rating: 4.5, isOpen: true),
    Restaurant(name: "Sushi Rápido", cuisine: "Japanese", distanceMinutes: 7, rating: 4.2, isOpen: true),
    Restaurant(name: "Green Bowl", cuisine: "Healthy", distanceMinutes: 3, rating: 4.7, isOpen: true),
    Restaurant(name: "Pizza del Parque", cuisine: "Italian", distanceMinutes: 9, rating: 4.0, isOpen: false),
    Restaurant(name: "Arepas & Co.", cuisine: "Colombian", distanceMinutes: 5, rating: 4.3, isOpen: true)
]

struct RestaurantsView: View {
    var body: some View {
        ZStack {
            CampusMealColors.sand100
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Restaurants")
                        .font(.largeTitle.bold())
                        .foregroundStyle(CampusMealColors.neutral900)

                    Text("Places near campus, ranked by distance")
                        .font(.subheadline)
                        .foregroundStyle(CampusMealColors.neutral500)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(mockRestaurants) { restaurant in
                            RestaurantRow(restaurant: restaurant)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

private struct RestaurantRow: View {
    let restaurant: Restaurant

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12)
                .fill(CampusMealColors.brand100)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "fork.knife")
                        .foregroundStyle(CampusMealColors.brand600)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.headline)
                    .foregroundStyle(CampusMealColors.neutral900)

                Text(restaurant.cuisine)
                    .font(.caption)
                    .foregroundStyle(CampusMealColors.neutral500)

                HStack(spacing: 10) {
                    Label("\(restaurant.distanceMinutes) min", systemImage: "figure.walk")
                    Label(String(format: "%.1f", restaurant.rating), systemImage: "star.fill")
                }
                .font(.caption2)
                .foregroundStyle(CampusMealColors.neutral700)
            }

            Spacer()

            Text(restaurant.isOpen ? "Open" : "Closed")
                .font(.caption2.bold())
                .foregroundStyle(restaurant.isOpen ? CampusMealColors.positive700 : CampusMealColors.neutral500)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(restaurant.isOpen ? CampusMealColors.positive100 : CampusMealColors.neutral100)
                .clipShape(Capsule())
        }
        .padding(12)
        .background(CampusMealColors.neutral0)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(CampusMealColors.sand200, lineWidth: 1)
        )
    }
}

#Preview {
    RestaurantsView()
}
