//
//  RootView.swift
//  CampusMeal
//
//  Created by Carlos Poveda on 18/9/26.
//

import SwiftUI

// MARK: - App entry flow (MS7 prototype)
//
// Login -> MainTabView (Home / Inventory / Decide / Profile), matching the
// Figma bottom navigation pattern. `isLoggedIn` is local, in-memory state
// standing in for real auth; Sprint 2 will replace it with the Session
// feature (Keychain-backed).
struct RootView: View {
    @State private var isLoggedIn = false

    var body: some View {
        if isLoggedIn {
            MainTabView()
        } else {
            LoginView(onLogin: { isLoggedIn = true })
        }
    }
}

#Preview {
    RootView()
}
