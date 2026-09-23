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
                PairingView()
            } else {
                HomeView()
            }
        }
        .task {
            await AppState.shared.refresh()
        }
    }
}
