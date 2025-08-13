//
//  ContentView.swift
//  Steps Toward
//
//  Created by Jared WIlliam Tamulynas on 8/12/25.
//

import SwiftUI
import Observation

struct ContentView: View {
    @Environment(AuthManager.self) private var authManager
    
    @State private var showLogin = true

    var body: some View {
        HomeView()
            .fullScreenCover(isPresented: $showLogin) {
                LoginView()
            }
            .onChange(of: authManager.authState) { _, newValue in
                showLogin = newValue == .signedOut
            }
            .task {
                await authManager.startAuthSession()
                showLogin = authManager.authState == .signedOut
            }
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
}
