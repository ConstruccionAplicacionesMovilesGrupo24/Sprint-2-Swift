//
//  RootView.swift
//  CampusMeal
//
//  Created by Carlos Poveda on 18/9/26.
//

import SwiftUI

// MARK: - App entry flow (MS7 prototype)
//
// Login -> Home -> Restaurants / Comparison, matching the Figma flow.
// `isLoggedIn` is local, in-memory state standing in for real auth; Sprint 2
// will replace it with the Session feature (Keychain-backed) and likely a
// NavigationStack-based coordinator once more flows are added.
struct RootView: View {
    @State private var isLoggedIn = false

    var body: some View {
        if isLoggedIn {
            NavigationStack {
                HomeView()
            }
        } else {
            LoginView(onLogin: { isLoggedIn = true })
        }
    }
}

#Preview {
    RootView()
}
