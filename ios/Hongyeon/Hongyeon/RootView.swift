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
        if locationManager.authorizationStatus == .notDetermined {
            LocationOnboardingView()
        } else {
            ContentView()
        }
    }
}
