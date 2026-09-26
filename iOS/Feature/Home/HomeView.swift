//
//  HomeView.swift
//  CampusMeal
//
//  Created by Carlos Poveda on 18/9/26.
//

import SwiftUI

// Expiring items come from BQ2 (`GET inventory/expiring?withinDays=3`) and are shown in
// the backend's priority order — no client-side re-sorting.
private enum ExpiringItemsState {
    case loading
    case loaded([InventoryItemDTO])
    case failed(String)
}

struct HomeView: View {
    @State private var expiringState: ExpiringItemsState = .loading
    @State private var contextStore = ContextStore.shared
    @State private var isShowingContext = false

    private let inventoryRepository = InventoryRepository()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Label("Context values are sample data · expiring items are live", systemImage: "info.circle")
                    .font(CampusMealTypography.caption)
                    .foregroundStyle(CampusMealColors.neutral500)

                Text("CampusMeal")
                    .font(CampusMealTypography.headingL)
                    .lineSpacing(CampusMealTypography.LineSpacing.headingL)
                    .foregroundStyle(CampusMealColors.neutral900)
                Text("Good afternoon, Juan Pablo")
                    .font(CampusMealTypography.displayL)
                    .lineSpacing(CampusMealTypography.LineSpacing.displayL)
                    .foregroundStyle(CampusMealColors.neutral900)
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day().hour().minute()))
                    .font(CampusMealTypography.bodyS)
                    .foregroundStyle(CampusMealColors.neutral500)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Your context right now")
                            .font(CampusMealTypography.headingM)
                            .foregroundStyle(CampusMealColors.neutral900)
                        Spacer()
                        Button("Change") { isShowingContext = true }
                            .font(CampusMealTypography.labelM)
                            .foregroundStyle(CampusMealColors.brand600)
                    }
                    ContextRow(label: "Campus", value: contextStore.current.campusDisplayName)
                    ContextRow(label: "Time available", value: "\(contextStore.current.availableMinutes) minutes")
                    ContextRow(label: "Budget", value: CampusMealFormat.cop(contextStore.current.maximumBudget))
                }
                .padding()
                .background(CampusMealColors.neutral0, in: RoundedRectangle(cornerRadius: 20))

                Text("Expiring soon")
                    .font(CampusMealTypography.headingM)
                    .foregroundStyle(CampusMealColors.neutral900)
                expiringItemsSection

                NavigationLink {
                    ComparisonView()
                } label: {
                    Text("Compare my options")
                        .font(CampusMealTypography.labelL)
                        .foregroundStyle(CampusMealColors.neutral900)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(CampusMealColors.brand500, in: RoundedRectangle(cornerRadius: 14))
                }

                HStack(spacing: 12) {
                    // Navigates to the Inventory feature once that issue lands.
                    Text("View inventory")
                        .font(CampusMealTypography.labelL)
                        .foregroundStyle(CampusMealColors.brand600)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(CampusMealColors.brand500, lineWidth: 1.5))

                    NavigationLink {
                        RestaurantsView()
                    } label: {
                        Text("Restaurants")
                            .font(CampusMealTypography.labelL)
                            .foregroundStyle(CampusMealColors.brand600)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(CampusMealColors.brand500, lineWidth: 1.5))
                    }
                }
            }
            .padding(24)
        }
        .background(CampusMealColors.neutral50)
        .task { await loadExpiringItems() }
        .refreshable { await loadExpiringItems() }
        .sheet(isPresented: $isShowingContext) {
            SetContextView()
        }
    }

    @ViewBuilder
    private var expiringItemsSection: some View {
        switch expiringState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding()
        case .failed(let message):
            VStack(alignment: .leading, spacing: 8) {
                // No "negative/error" color in the design system yet — same choice as LoginView.
                Text(message)
                    .font(CampusMealTypography.bodyS)
                    .foregroundStyle(.red)
                Button("Try again") {
                    Task { await loadExpiringItems() }
                }
                .font(CampusMealTypography.labelM)
                .foregroundStyle(CampusMealColors.brand600)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CampusMealColors.neutral0, in: RoundedRectangle(cornerRadius: 20))
        case .loaded(let items) where items.isEmpty:
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(CampusMealColors.neutral500)
                Text("Nothing expires in the next \(InventoryRepository.defaultWithinDays) days.")
                    .font(CampusMealTypography.bodyM)
                    .foregroundStyle(CampusMealColors.neutral500)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CampusMealColors.neutral0, in: RoundedRectangle(cornerRadius: 20))
        case .loaded(let items):
            ForEach(items) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(CampusMealTypography.headingM)
                            .foregroundStyle(CampusMealColors.neutral900)
                        Text("\(item.quantityDescription) · expires \(item.expirationDate)")
                            .font(CampusMealTypography.bodyS)
                            .foregroundStyle(CampusMealColors.neutral500)
                    }
                    Spacer()
                    UrgencyBadge(item: item)
                }
                .padding()
                .background(CampusMealColors.neutral0, in: RoundedRectangle(cornerRadius: 20))
            }
        }
    }

    private func loadExpiringItems() async {
        if case .loaded = expiringState {} else { expiringState = .loading }
        do {
            let items = try await inventoryRepository.fetchExpiringItems()
            expiringState = .loaded(items)
        } catch APIError.unauthorized {
            expiringState = .failed("Your session expired. Please log in again.")
        } catch {
            expiringState = .failed("Couldn't load your expiring items. Check your connection and try again.")
        }
    }
}

private struct ContextRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label)
                .font(CampusMealTypography.bodyM)
                .foregroundStyle(CampusMealColors.neutral500)
            Spacer()
            Text(value)
                .font(CampusMealTypography.labelM)
                .foregroundStyle(CampusMealColors.neutral900)
        }
    }
}

/// Urgency indicator for an inventory item. Status is conveyed through text
/// and icon as well as color (MS7 §3.3): brand700 (today) / accent500 (soon).
private struct UrgencyBadge: View {
    let item: InventoryItemDTO

    var body: some View {
        Label(item.expirationLabel, systemImage: item.isDueToday ? "exclamationmark.triangle.fill" : "circle.fill")
            .font(CampusMealTypography.labelM)
            .foregroundStyle(item.isDueToday ? CampusMealColors.brand700 : CampusMealColors.accent700)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background((item.isDueToday ? CampusMealColors.brand100 : CampusMealColors.accent100), in: Capsule())
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
