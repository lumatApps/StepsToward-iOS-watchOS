//
//  AuthManager.swift
//  Steps Toward
//
//  Created by Jared William Tamulynas on 8/12/25.
//

import Foundation
import AuthenticationServices
import FirebaseAuth
import FirebaseCore
import Observation
import GoogleSignIn

enum AuthState {
    case authenticated      // Signed in anonymously
    case signedIn           // Signed in with a non-anonymous provider
    case signedOut          // Not signed in
}

enum AuthError: LocalizedError, Equatable {
    case emailAlreadyInUse
    case credentialAlreadyInUse
    case providerAlreadyLinked
    case accountExistsWithDifferentCredential
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .emailAlreadyInUse:
            return "This email is already associated with another account. You've been signed in to that existing account."
        case .credentialAlreadyInUse:
            return "This account is already linked with your profile. You've been signed in."
        case .providerAlreadyLinked:
            return "This sign-in method is already linked to your account."
        case .accountExistsWithDifferentCredential:
            return "An account already exists with this email. Please sign in with the correct provider."
        case .unknownError(let message):
            return "Authentication error: \(message)"
        }
    }
}

@Observable
final class AuthManager {
    var user: FirebaseAuth.User?
    var authState: AuthState = .signedOut

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var hasAttemptedRestore = false

    init() {
        // Avoid touching FirebaseAuth before FirebaseApp is configured (e.g., in previews)
        guard FirebaseApp.app() != nil else { return }
        configureAuthStateChanges()
        verifySignInWithAppleID()
    }
    
    // Call this after the app has fully loaded
    @MainActor
    func startAuthSession() {
        // Only try to restore once per app session
        guard !hasAttemptedRestore else { return }
        hasAttemptedRestore = true
        
        Task {
            await tryRestorePreviousSignIn()
        }
    }

    deinit {
        removeAuthStateListener()
    }

    // MARK: - Auth State Listening

    func configureAuthStateChanges() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            print("Auth changed: \(user != nil)")
            Task { @MainActor in
                self.updateState(user: user)
            }
        }
    }

    func removeAuthStateListener() {
        if let authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
        authStateHandle = nil
    }

    @MainActor
    func updateState(user: FirebaseAuth.User?) {
        self.user = user
        let isAuthenticatedUser = user != nil
        let isAnonymous = user?.isAnonymous ?? false

        if isAuthenticatedUser {
            self.authState = isAnonymous ? .authenticated : .signedIn
        } else {
            self.authState = .signedOut
        }
    }

    // MARK: - Anonymous Auth

    func signInAnonymously() async throws -> AuthDataResult? {
        // Check if we already have an anonymous user
        if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
            print("FirebaseAuthSuccess: Already signed in anonymously, UID:(\(currentUser.uid))")
            // Just return nil since we're already in the correct state
            return nil
        }
        
        do {
            let result = try await Auth.auth().signInAnonymously()
            print("FirebaseAuthSuccess: Sign in anonymously, UID:(\(String(describing: result.user.uid)))")
            
            // Mark that we've handled initial auth flow
            await MainActor.run {
                hasAttemptedRestore = true
            }
            
            return result
        } catch {
            print("FirebaseAuthError: failed to sign in anonymously: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Account Management
    
    func deleteAnonymousAccount() async throws {
        if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
            do {
                try await currentUser.delete()
                print("Anonymous account deleted successfully")
            } catch {
                print("Failed to delete anonymous account: \(error)")
                throw error
            }
        }
    }

    // MARK: - Sign Out

    func signOut() async throws {
        if let currentUser = Auth.auth().currentUser {
            // Don't allow signing out anonymous users - they should stay anonymous
            guard !currentUser.isAnonymous else {
                print("Cannot sign out anonymous users")
                return
            }
            
            do {
                firebaseProviderSignOut(currentUser)
                try Auth.auth().signOut()
                
                // Reset restoration flag so user stays signed out
                await MainActor.run {
                    hasAttemptedRestore = false
                }
            } catch let error as NSError {
                print("FirebaseAuthError: failed to sign out from Firebase, \(error)")
                throw error
            }
        }
    }

    // MARK: - Generic Sign-in / Link helpers
    
    private let authLinkErrors: [AuthErrorCode] = [
        .emailAlreadyInUse,
        .credentialAlreadyInUse,
        .providerAlreadyLinked
    ]

    private func authenticateUser(credentials: AuthCredential) async throws -> AuthDataResult? {
        if Auth.auth().currentUser != nil {
            return try await authLink(credentials: credentials)
        } else {
            return try await authSignIn(credentials: credentials)
        }
    }

    private func authSignIn(credentials: AuthCredential) async throws -> AuthDataResult? {
        do {
            let result = try await Auth.auth().signIn(with: credentials)
            await updateState(user: result.user)
            return result
        } catch {
            print("FirebaseAuthError: signIn(with:) failed. \(error)")
            throw error
        }
    }

    private func authLink(credentials: AuthCredential) async throws -> AuthDataResult? {
        do {
            guard let user = Auth.auth().currentUser else { return nil }
            let result = try await user.link(with: credentials)
            await updateDisplayName(for: result.user)
            await updateState(user: result.user)
            return result
        } catch {
            print("FirebaseAuthError: link(with:) failed, \(error)")
            
            // Handle common linking errors by falling back to sign-in
            if let error = error as NSError? {
                if let code = AuthErrorCode(rawValue: error.code),
                   authLinkErrors.contains(code) {
                    print("Linking failed, falling back to sign-in. Error code: \(code)")
                    
                    // For Apple credentials, get updated credentials from error if available
                    let updatedCredentials: AuthCredential
                    if credentials.provider == "apple.com",
                       let appleCredentials = error.userInfo[AuthErrorUserInfoUpdatedCredentialKey] as? AuthCredential {
                        updatedCredentials = appleCredentials
                        print("Using updated Apple credentials from error")
                    } else {
                        updatedCredentials = credentials
                    }
                    
                    // Sign in with the credentials instead of linking
                    // Note: This means the anonymous account data will be lost
                    let result = try await authSignIn(credentials: updatedCredentials)
                    
                    // Throw a custom error to inform the UI about what happened
                    if code == .emailAlreadyInUse {
                        throw AuthError.emailAlreadyInUse
                    } else if code == .credentialAlreadyInUse {
                        throw AuthError.credentialAlreadyInUse
                    } else if code == .providerAlreadyLinked {
                        throw AuthError.providerAlreadyLinked
                    }
                    
                    return result
                }
            }
            
            throw error
        }
    }

    private func updateDisplayName(for user: FirebaseAuth.User) async {
        if let currentDisplayName = Auth.auth().currentUser?.displayName, !currentDisplayName.isEmpty {
            return
        } else {
            let displayName = user.providerData.first?.displayName
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            do {
                try await changeRequest.commitChanges()
            } catch {
                print("FirebaseAuthError: Failed to update the user's displayName. \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Google

    func googleAuth(_ user: GIDGoogleUser) async throws -> AuthDataResult? {
        guard let idToken = user.idToken?.tokenString else { return nil }
        let credentials = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: user.accessToken.tokenString
        )
        do {
            return try await authenticateUser(credentials: credentials)
        } catch {
            print("FirebaseAuthError: googleAuth(user:) failed. \(error)")
            throw error
        }
    }

    func firebaseProviderSignOut(_ user: FirebaseAuth.User) {
        let providerIDs = user.providerData.map { $0.providerID }.joined(separator: ", ")
        if providerIDs.contains("google.com") {
            GoogleSignInManager.shared.signOutFromGoogle()
        }
        // Apple doesn't require explicit sign-out like Google
    }
    
    // MARK: - Apple
    
    func appleAuth(
        _ appleIDCredential: ASAuthorizationAppleIDCredential,
        nonce: String?
    ) async throws -> AuthDataResult? {
        guard let nonce = nonce else {
            fatalError("Invalid state: A login callback was received, but no login request was sent.")
        }
        
        guard let appleIDToken = appleIDCredential.identityToken else {
            print("Unable to fetch identity token")
            return nil
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
            return nil
        }
        
        let credentials = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                       rawNonce: nonce,
                                                       fullName: appleIDCredential.fullName)
        
        do {
            return try await authenticateUser(credentials: credentials)
        } catch {
            print("FirebaseAuthError: appleAuth(appleIDCredential:nonce:) failed. \(error)")
            throw error
        }
    }
    
    func verifySignInWithAppleID() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let providerData = Auth.auth().currentUser?.providerData
        if let appleProviderData = providerData?.first(where: { $0.providerID == "apple.com" }) {
            Task {
                do {
                    let credentialState = try await appleIDProvider.credentialState(forUserID: appleProviderData.uid)
                    switch credentialState {
                    case .authorized:
                        break // The Apple ID credential is valid.
                    case .revoked, .notFound:
                        // The Apple ID credential is either revoked or was not found, so show the sign-in UI.
                        do {
                            try await self.signOut()
                        } catch {
                            print("FirebaseAuthError: signOut() failed. \(error)")
                        }
                    default:
                        break
                    }
                } catch {
                    print("Error checking Apple ID credential state: \(error)")
                }
            }
        }
    }
    
    @MainActor
    private func tryRestorePreviousSignIn() async {
        // Only restore if user is not already signed in to Firebase
        guard Auth.auth().currentUser == nil else {
            print("User already signed in to Firebase")
            return
        }
        
        // Only restore Google sign-in if user was previously signed in with a provider (not anonymous)
        do {
            if let googleUser = try await GoogleSignInManager.shared.restorePreviousSignIn() {
                // Check if this Google account was previously linked to a non-anonymous Firebase account
                guard let idToken = googleUser.idToken?.tokenString else {
                    print("No ID token available")
                    return
                }
                let credentials = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: googleUser.accessToken.tokenString
                )
                _ = try await authSignIn(credentials: credentials)
                print("Restored previous non-anonymous Google sign-in")
            }
        } catch {
            print("No previous non-anonymous sign-in to restore: \(error)")
            // Don't restore anonymous sessions - let user choose their preferred sign-in method
        }
    }
}


