//
//  LoginView.swift
//  CampusMeal
//
//  Created by Daniel Vargas on 17/9/26.
//

import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        ZStack {
            CampusMealColors.sand100
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(CampusMealColors.brand500)

                    Text("CampusMeal")
                        .font(.largeTitle.bold())
                        .foregroundStyle(CampusMealColors.neutral900)

                    Text("Find what to eat, nearby and on time")
                        .font(.subheadline)
                        .foregroundStyle(CampusMealColors.neutral500)
                }

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.caption)
                            .foregroundStyle(CampusMealColors.neutral700)
                        TextField("youremail@uniandes.edu.co", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .padding(12)
                            .background(CampusMealColors.neutral0)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(CampusMealColors.sand300, lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.caption)
                            .foregroundStyle(CampusMealColors.neutral700)
                        SecureField("••••••••", text: $password)
                            .padding(12)
                            .background(CampusMealColors.neutral0)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(CampusMealColors.sand300, lineWidth: 1)
                            )
                    }
                }

                Button {
                    // Mock for MS7 — real authentication logic (Keychain + backend) is implemented in Sprint 2.
                } label: {
                    Text("Sign In")
                        .font(.headline)
                        .foregroundStyle(CampusMealColors.neutral0)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(CampusMealColors.brand500)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    // Navigation to sign up — pending.
                } label: {
                    Text("Don't have an account? Sign up")
                        .font(.footnote)
                        .foregroundStyle(CampusMealColors.brand600)
                }

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 28)
        }
    }
}

#Preview {
    LoginView()
}
