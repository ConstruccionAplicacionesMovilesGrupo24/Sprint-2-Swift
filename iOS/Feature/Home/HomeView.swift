//
//  HomeView.swift
//  CampusMeal
//
//  Created by Carlos Poveda on 18/9/26.
//

import SwiftUI

// Demonstration inventory data only; entered manually — not synced with any
// real pantry or sensor. Matches the ingredients referenced by the "Cook at
// home" recommendation in ComparisonView (Figma frame 11), so Home and
// Comparison stay consistent.
private struct InventoryItem: Identifiable {
    let id: String
    let name: String
    let quantityDescription: String
    let category: String
    let daysUntilExpiration: Int

    var isToday: Bool { daysUntilExpiration <= 0 }

    var expirationLabel: String {
        isToday
            ? "Due today"
            : "Due in \(daysUntilExpiration) day\(daysUntilExpiration == 1 ? "" : "s")"
    }
}

private let mockExpiringItems: [InventoryItem] = [
    InventoryItem(id: "milk", name: "Whole milk", quantityDescription: "1 L",
                  category: "Dairy", daysUntilExpiration: 0),
    InventoryItem(id: "tomatoes", name: "Tomatoes", quantityDescription: "6 units",
                  category: "Vegetables", daysUntilExpiration: 2)
]

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Label("Visual prototype · sample data", systemImage: "info.circle")
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
                        // Navigates to the Context feature once #Context-issue lands.
                        Text("Change")
                            .font(CampusMealTypography.labelM)
                            .foregroundStyle(CampusMealColors.brand600)
                    }
                    ContextRow(label: "Campus", value: "Uniandes")
                    ContextRow(label: "Time available", value: "45 minutes")
                    ContextRow(label: "Budget", value: "$20,000")
                }
                .padding()
                .background(CampusMealColors.neutral0, in: RoundedRectangle(cornerRadius: 20))

                Text("Expiring soon")
                    .font(CampusMealTypography.headingM)
                    .foregroundStyle(CampusMealColors.neutral900)
                ForEach(mockExpiringItems) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(CampusMealTypography.headingM)
                                .foregroundStyle(CampusMealColors.neutral900)
                            Text("\(item.quantityDescription) · \(item.category)")
                                .font(CampusMealTypography.bodyS)
                                .foregroundStyle(CampusMealColors.neutral500)
                        }
                        Spacer()
                        UrgencyBadge(item: item)
                    }
                    .padding()
                    .background(CampusMealColors.neutral0, in: RoundedRectangle(cornerRadius: 20))
                }

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
    let item: InventoryItem

    var body: some View {
        Label(item.expirationLabel, systemImage: item.isToday ? "exclamationmark.triangle.fill" : "circle.fill")
            .font(CampusMealTypography.labelM)
            .foregroundStyle(item.isToday ? CampusMealColors.brand700 : CampusMealColors.accent700)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background((item.isToday ? CampusMealColors.brand100 : CampusMealColors.accent100), in: Capsule())
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
