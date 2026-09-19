//
//  RootView.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 9/11/26.
//

import SwiftUI
import CoreLocation

struct RootView: View {
    @ObservedObject private var locationManager = LocationManager.shared
    @ObservedObject private var appState = AppState.shared

    var body: some View {
        Group {
            if !appState.isSignedIn {
                SignInView()
            } else if locationManager.authorizationStatus == .notDetermined {
                LocationOnboardingView()
            } else if !appState.isPaired {
                PairingPlaceholderView()
            } else {
                ContentView()
            }
        }
        .task {
            await AppState.shared.refresh()
        }
    }
}

struct PairingPlaceholderView: View {
    var body: some View {
        Text("Pairing screen coming in issue #94")
    }
}
