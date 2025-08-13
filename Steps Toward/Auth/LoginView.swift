//
//  LoginView.swift
//  Steps Toward
//
//  Created by Jared WIlliam Tamulynas on 8/12/25.
//

import SwiftUI
import Observation
import GoogleSignInSwift
import AuthenticationServices

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.walk.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            Text("Welcome to Steps Toward")
                .font(.largeTitle).bold()

            Text("Track your daily steps and achieve your fitness goals")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                // Google Sign In
                GoogleSignInButton(style: .wide) {
                    Task { await signInWithGoogle() }
                }
                
                // Apple Sign In
                SignInWithAppleButton(
                    onRequest: { request in
                        AppleSignInManager.shared.requestAppleAuthorization(request)
                    },
                    onCompletion: { result in
                        handleAppleID(result)
                    }
                )
                .frame(height: 48)
                .cornerRadius(10)
                
                // Anonymous/Skip option
                Button {
                    signAnonymously()
                } label: {
                    Text("Continue as Guest")
                        .font(.body)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .foregroundStyle(.primary)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.primary, lineWidth: 1)
                        )
                }
            }
        }
        .padding()
        .alert("Authentication Notice", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .task {
            await authManager.startAuthSession()
        }
    }

    private func signAnonymously() {
        Task {
            do {
                _ = try await authManager.signInAnonymously()
            } catch {
                print("SignInAnonymouslyError: \(error)")
                errorMessage = "Failed to continue as guest. Please try again."
                showErrorAlert = true
            }
        }
    }

    @MainActor
    private func signInWithGoogle() async {
        do {
            guard let user = try await GoogleSignInManager.shared.signInWithGoogle() else {
                print("Google sign-in cancelled or failed")
                return
            }
            let result = try await authManager.googleAuth(user)
            if let result = result {
                print("GoogleSignInSuccess: \(result.user.uid)")
                // Dismiss removed
            }
        } catch let authError as AuthError {
            // Handle custom auth errors with user-friendly messages
            print("GoogleSignInError: \(authError)")
            errorMessage = authError.localizedDescription
            showErrorAlert = true
            // Dismiss removed
        } catch {
            print("GoogleSignInError: failed to sign in with Google, \(error))")
            errorMessage = "Failed to sign in with Google. Please try again."
            showErrorAlert = true
        }
    }
    
    private func handleAppleID(_ result: Result<ASAuthorization, Error>) {
        if case let .success(auth) = result {
            guard let appleIDCredentials = auth.credential as? ASAuthorizationAppleIDCredential else {
                print("AppleAuthorization failed: AppleID credential not available")
                return
            }
            
            Task {
                do {
                    let result = try await authManager.appleAuth(
                        appleIDCredentials,
                        nonce: AppleSignInManager.nonce
                    )
                    if let result = result {
                        print("AppleSignInSuccess: \(result.user.uid)")
                        // Dismiss removed
                    }
                } catch let authError as AuthError {
                    // Handle custom auth errors with user-friendly messages
                    print("AppleAuthorization failed: \(authError)")
                    await MainActor.run {
                        errorMessage = authError.localizedDescription
                        showErrorAlert = true
                        // Dismiss removed
                    }
                } catch {
                    print("AppleAuthorization failed: \(error)")
                    await MainActor.run {
                        errorMessage = "Failed to sign in with Apple. Please try again."
                        showErrorAlert = true
                    }
                }
            }
        }
        else if case let .failure(error) = result {
            print("AppleAuthorization failed: \(error)")
            // Here you can show error message to user.
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthManager())
}


