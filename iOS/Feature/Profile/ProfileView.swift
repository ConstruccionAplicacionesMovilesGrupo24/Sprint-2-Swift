//
//  ProfileView.swift
//  CampusMeal
//

import SwiftUI

// Placeholder for MS7 — real profile data (session, preferences, sign-out)
// is implemented in Sprint 2 alongside the Session/auth feature.
struct ProfileView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 40))
                .foregroundStyle(CampusMealColors.neutral500)
            Text("Profile")
                .font(CampusMealTypography.headingXL)
                .foregroundStyle(CampusMealColors.neutral900)
            Text("Coming in Sprint 2")
                .font(CampusMealTypography.bodyM)
                .foregroundStyle(CampusMealColors.neutral500)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CampusMealColors.neutral50)
    }
}

#Preview {
    ProfileView()
}
