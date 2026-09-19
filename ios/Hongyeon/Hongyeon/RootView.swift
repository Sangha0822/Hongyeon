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

    var body: some View {
        Group {
            if locationManager.authorizationStatus == .notDetermined {
                LocationOnboardingView()
            } else {
                ContentView()
            }
        }
        .task {
            await AppState.shared.refresh()
        }
    }
}
