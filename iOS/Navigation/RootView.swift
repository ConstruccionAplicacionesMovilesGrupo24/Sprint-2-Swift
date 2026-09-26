//
//  RootView.swift
//  CampusMeal
//
//  Created by Carlos Poveda on 18/9/26.
//

import SwiftUI

// MARK: - App entry flow
//
// Login -> MainTabView (Home / Inventory / Decide / Profile), matching the
// Figma bottom navigation pattern. `SessionManager.isLoggedIn` reflects
// whether a token pair is in Keychain; LoginView drives it indirectly by
// calling AuthRepository, which calls SessionManager.completeLogin().
struct RootView: View {
    @State private var session = SessionManager.shared

    var body: some View {
        if session.isLoggedIn {
            MainTabView()
        } else {
            LoginView()
        }
    }
}

#Preview {
    RootView()
}
