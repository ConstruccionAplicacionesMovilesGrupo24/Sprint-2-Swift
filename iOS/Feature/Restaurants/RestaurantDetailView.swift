//
//  RestaurantDetailView.swift
//  CampusMeal
//

import SwiftUI

// Detail screen backed by `GET restaurants/:id`. The endpoint has no request origin, so its
// walking/total times are always null (routeProviderStatus UNAVAILABLE) — they are not shown.
struct RestaurantDetailView: View {
    let restaurantId: String
    let name: String

    @State private var detail: RestaurantDetailResponse?
    @State private var errorMessage: String?

    private let repository = RestaurantsRepository()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let detail {
                    header(detail)
                    mealsSection(detail.meals)
                } else if let errorMessage {
                    // No "negative/error" color in the design system yet — same choice as LoginView.
                    Text(errorMessage)
                        .font(CampusMealTypography.bodyM)
                        .foregroundStyle(.red)
                    Button("Try again") { Task { await load() } }
                        .font(CampusMealTypography.labelM)
                        .foregroundStyle(CampusMealColors.brand600)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                }
            }
            .padding(20)
        }
        .background(CampusMealColors.neutral50)
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .task { await load() }
    }

    private func header(_ detail: RestaurantDetailResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(detail.restaurant.name)
                    .font(CampusMealTypography.headingL)
                    .foregroundStyle(CampusMealColors.neutral900)
                Spacer()
                StatusPill(status: detail.restaurant.openingStatus)
            }
            Text("\(detail.restaurant.category) · ★ \(String(format: "%.1f", detail.restaurant.averageRating))")
                .font(CampusMealTypography.bodyS)
                .foregroundStyle(CampusMealColors.neutral500)
            Label(detail.address, systemImage: "mappin.and.ellipse")
                .font(CampusMealTypography.bodyM)
                .foregroundStyle(CampusMealColors.neutral700)
            Text("From \(CampusMealFormat.cop(detail.restaurant.minimumMealPrice))")
                .font(CampusMealTypography.labelL)
                .foregroundStyle(CampusMealColors.brand700)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CampusMealColors.neutral0)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func mealsSection(_ meals: [MealDTO]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Available meals")
                .font(CampusMealTypography.headingM)
                .foregroundStyle(CampusMealColors.neutral900)
            if meals.isEmpty {
                Text("No meals available right now.")
                    .font(CampusMealTypography.bodyM)
                    .foregroundStyle(CampusMealColors.neutral500)
            }
            ForEach(meals) { meal in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(meal.name)
                            .font(CampusMealTypography.labelL)
                            .foregroundStyle(CampusMealColors.neutral900)
                        if !meal.dietaryTags.isEmpty {
                            Text(meal.dietaryTags.map(\.label).joined(separator: " · "))
                                .font(CampusMealTypography.caption)
                                .foregroundStyle(CampusMealColors.neutral500)
                        }
                    }
                    Spacer()
                    Text(CampusMealFormat.cop(meal.price))
                        .font(CampusMealTypography.labelL)
                        .foregroundStyle(CampusMealColors.neutral900)
                }
                .padding(12)
                .background(CampusMealColors.neutral0)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func load() async {
        guard detail == nil else { return }
        errorMessage = nil
        do {
            detail = try await repository.fetchDetail(restaurantId: restaurantId)
        } catch APIError.notFound {
            errorMessage = "This restaurant is no longer available."
        } catch APIError.unauthorized {
            errorMessage = "Your session expired. Please log in again."
        } catch {
            errorMessage = "Couldn't load this restaurant. Check your connection and try again."
        }
    }
}

#Preview {
    NavigationStack {
        RestaurantDetailView(restaurantId: "preview", name: "The Garden")
    }
}
