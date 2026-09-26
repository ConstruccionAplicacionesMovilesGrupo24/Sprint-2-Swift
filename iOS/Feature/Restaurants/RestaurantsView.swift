//
//  RestaurantsView.swift
//  CampusMeal
//
//  Created by Daniel Vargas on 17/9/26.
//

import SwiftUI

// Search context sent to BQ4. Core/Location is still empty and the Context feature is not
// built yet, so this uses the manual-campus fallback (Uniandes coordinates + campusId) and
// the same sample values Home shows — the backend applies identical rules to both origins.
struct RestaurantSearchContext {
    var latitude = 4.6025
    var longitude = -74.0653
    var campusId: String? = "campus-001"
    var availableMinutes = 45
    var maximumBudget = 20_000
    var dietaryPreferences: [DietaryTag] = [.vegetarian]
    var includeDelivery = true

    var summary: String {
        let diet = dietaryPreferences.map(\.label).joined(separator: ", ")
        return "\(availableMinutes) min · COP \(maximumBudget.formatted(.number.locale(Locale(identifier: "en_US"))))"
            + (diet.isEmpty ? "" : " · \(diet)")
    }

    func request(at date: Date = .now) -> RestaurantSearchRequest {
        RestaurantSearchRequest(
            location: GeoLocation(latitude: latitude, longitude: longitude),
            campusId: campusId,
            availableMinutes: availableMinutes,
            maximumBudget: maximumBudget,
            dietaryPreferences: dietaryPreferences,
            includeDelivery: includeDelivery,
            requestedAt: CampusMealFormat.utcTimestamp(date)
        )
    }
}

private enum SearchState {
    case loading
    case loaded(RestaurantSearchResponse)
    case failed(String)
}

struct RestaurantsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var state: SearchState = .loading

    var context = RestaurantSearchContext()
    private let repository = RestaurantsRepository()

    var body: some View {
        ZStack {
            CampusMealColors.neutral50
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(CampusMealColors.neutral900)
                    }

                    Text("Nearby restaurants")
                        .font(CampusMealTypography.headingL)
                        .foregroundStyle(CampusMealColors.neutral900)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                HStack {
                    Text(context.summary)
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

                content
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await search() }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            VStack(spacing: 12) {
                // No "negative/error" color in the design system yet — same choice as LoginView.
                Text(message)
                    .font(CampusMealTypography.bodyM)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                Button("Try again") { Task { await search() } }
                    .font(CampusMealTypography.labelM)
                    .foregroundStyle(CampusMealColors.brand600)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let response):
            ScrollView {
                VStack(spacing: 12) {
                    if response.routeProviderStatus != .available {
                        RouteStatusBanner(status: response.routeProviderStatus)
                    }
                    if response.restaurants.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 32))
                                .foregroundStyle(CampusMealColors.neutral500)
                            Text("No open restaurant fits your time, budget and diet right now.")
                                .font(CampusMealTypography.bodyM)
                                .foregroundStyle(CampusMealColors.neutral500)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                    } else {
                        // Backend order is the ranking — displayed as received.
                        ForEach(response.restaurants) { restaurant in
                            RestaurantCard(
                                restaurant: restaurant,
                                updatedLabel: updatedLabel(response.lastUpdatedAt)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .refreshable { await search() }
        }
    }

    private func search() async {
        if case .loaded = state {} else { state = .loading }
        do {
            state = .loaded(try await repository.search(context.request()))
        } catch APIError.unauthorized {
            state = .failed("Your session expired. Please log in again.")
        } catch {
            state = .failed("Couldn't load restaurants. Check your connection and try again.")
        }
    }

    private func updatedLabel(_ lastUpdatedAt: String) -> String {
        guard let date = CampusMealFormat.instant(lastUpdatedAt) else { return "Updated just now" }
        return "Updated \(date.formatted(date: .omitted, time: .shortened))"
    }
}

private struct RouteStatusBanner: View {
    let status: RouteProviderStatus

    var body: some View {
        Label(
            status == .partial
                ? "Walking times are unavailable for some restaurants."
                : "Walking times are unavailable right now. Results still match your budget and diet.",
            systemImage: "figure.walk"
        )
        .font(CampusMealTypography.bodyS)
        .foregroundStyle(CampusMealColors.neutral700)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CampusMealColors.neutral100)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct RestaurantCard: View {
    let restaurant: RestaurantDTO
    let updatedLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(restaurant.name)
                    .font(CampusMealTypography.headingM)
                    .foregroundStyle(CampusMealColors.neutral900)

                Spacer()

                StatusPill(status: restaurant.openingStatus)
            }

            Text(tagsLine)
                .font(CampusMealTypography.bodyS)
                .foregroundStyle(CampusMealColors.neutral500)

            HStack(spacing: 10) {
                // walkingMinutes / estimatedTotalMinutes are null when the route is unknown.
                StatChip(value: restaurant.walkingMinutes.map { "\($0) min" } ?? "—", label: "Walk")
                StatChip(value: restaurant.estimatedTotalMinutes.map { "\($0) min" } ?? "—", label: "Total")
                StatChip(value: CampusMealFormat.cop(restaurant.minimumMealPrice), label: "From")
            }

            if !restaurant.recommendationReason.isEmpty {
                Text(restaurant.recommendationReason)
                    .font(CampusMealTypography.bodyS)
                    .foregroundStyle(CampusMealColors.neutral700)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CampusMealColors.accent50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            HStack {
                Text(updatedLabel)
                    .font(CampusMealTypography.caption)
                    .foregroundStyle(CampusMealColors.neutral500)

                Spacer()

                NavigationLink {
                    RestaurantDetailView(restaurantId: restaurant.id, name: restaurant.name)
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

    private var tagsLine: String {
        let diet = restaurant.dietaryTags.map(\.label)
        return ([restaurant.category] + diet).joined(separator: " · ")
            + " · ★ \(String(format: "%.1f", restaurant.averageRating))"
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

struct StatusPill: View {
    let status: OpeningStatus

    private var text: String {
        switch status {
        case .open: "Open now"
        case .closingSoon: "Closing soon"
        case .closed: "Closed"
        case .unknown: "Hours unknown"
        }
    }

    private var foreground: Color {
        switch status {
        case .open: CampusMealColors.positive700
        case .closingSoon: CampusMealColors.accent700
        case .closed, .unknown: CampusMealColors.neutral700
        }
    }

    private var background: Color {
        switch status {
        case .open: CampusMealColors.positive100
        case .closingSoon: CampusMealColors.accent100
        case .closed, .unknown: CampusMealColors.neutral100
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            if status == .open {
                Circle()
                    .fill(CampusMealColors.positive500)
                    .frame(width: 6, height: 6)
            } else if status == .closingSoon {
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
    NavigationStack {
        RestaurantsView()
    }
}
