//
//  GoogleSignInManager.swift
//  Steps Toward
//
//  Created by Jared William Tamulynas on 8/12/25.
//

import Foundation
import UIKit
import GoogleSignIn

final class GoogleSignInManager {

    static let shared = GoogleSignInManager()

    private init() {}

    @MainActor
    func signInWithGoogle() async throws -> GIDGoogleUser? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        return result.user
    }
    
    @MainActor
    func restorePreviousSignIn() async throws -> GIDGoogleUser? {
        guard GIDSignIn.sharedInstance.hasPreviousSignIn() else { return nil }
        return try await GIDSignIn.sharedInstance.restorePreviousSignIn()
    }

    func signOutFromGoogle() {
        GIDSignIn.sharedInstance.signOut()
    }
}


