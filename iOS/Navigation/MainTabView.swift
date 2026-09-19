//
//  MainTabView.swift
//  CampusMeal
//

import SwiftUI

// Bottom tab bar matching the Figma navigation pattern (Home / Inventory /
// Decide / Profile as peer destinations). Inventory and Profile are MS7
// placeholders — real functionality lands in Sprint 2.
struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                InventoryView()
            }
            .tabItem {
                Label("Inventory", systemImage: "shippingbox.fill")
            }

            NavigationStack {
                ComparisonView()
            }
            .tabItem {
                Label("Decide", systemImage: "chart.bar.fill")
            }

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
        .tint(CampusMealColors.brand500)
    }
}

#Preview {
    MainTabView()
}
