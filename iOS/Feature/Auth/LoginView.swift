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
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let authRepository = AuthRepository()

    var body: some View {
        ZStack {
            CampusMealColors.neutral50
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(CampusMealColors.brand500)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text("CM")
                            .font(CampusMealTypography.headingM)
                            .foregroundStyle(CampusMealColors.neutral0)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back")
                        .font(CampusMealTypography.headingXL)
                        .foregroundStyle(CampusMealColors.neutral900)

                    Text("Decide what to eat today in under a minute.")
                        .font(CampusMealTypography.bodyM)
                        .foregroundStyle(CampusMealColors.neutral500)
                }

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Institutional email")
                            .font(CampusMealTypography.labelM)
                            .foregroundStyle(CampusMealColors.neutral700)
                        TextField("user@uniandes.edu.co", text: $email)
                            .font(CampusMealTypography.bodyL)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .padding(14)
                            .background(CampusMealColors.neutral0)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(CampusMealTypography.labelM)
                            .foregroundStyle(CampusMealColors.neutral700)
                        SecureField("••••••••••", text: $password)
                            .font(CampusMealTypography.bodyL)
                            .padding(14)
                            .background(CampusMealColors.neutral0)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    HStack {
                        Spacer()
                        Button {
                            // Password recovery flow — implemented in Sprint 2.
                        } label: {
                            Text("Forgot password?")
                                .font(CampusMealTypography.labelM)
                                .foregroundStyle(CampusMealColors.brand600)
                        }
                    }

                    if let errorMessage {
                        // The design system has no "negative/error" color yet (not
                        // extracted from Figma) — using the system red rather than
                        // guessing a hex value that might not match the real one.
                        Text(errorMessage)
                            .font(CampusMealTypography.bodyS)
                            .foregroundStyle(.red)
                    }
                }

                Button {
                    Task { await logIn() }
                } label: {
                    Text(isLoading ? "Logging in…" : "Log in")
                        .font(CampusMealTypography.labelL)
                        .foregroundStyle(CampusMealColors.neutral900)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(CampusMealColors.brand500)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isLoading)

                Spacer()

                HStack(spacing: 4) {
                    Spacer()
                    Text("Don't have an account?")
                        .font(CampusMealTypography.bodyM)
                        .foregroundStyle(CampusMealColors.neutral500)
                    Button {
                        // Navigation to sign up — pending.
                    } label: {
                        Text("Create account")
                            .font(CampusMealTypography.labelM)
                            .foregroundStyle(CampusMealColors.brand600)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 80)
            .padding(.bottom, 40)
        }
    }

    private func logIn() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await authRepository.login(email: email, password: password)
        } catch let error as APIError {
            errorMessage = message(for: error)
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
    }

    private func message(for error: APIError) -> String {
        switch error {
        case .unauthorized:
            "Invalid email or password."
        case .validation(let message):
            message
        case .transport:
            "Couldn't reach the server. Check your connection and try again."
        default:
            "Something went wrong. Please try again."
        }
    }
}

#Preview {
    LoginView()
}
