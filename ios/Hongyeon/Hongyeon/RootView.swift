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
    @State private var devMenuTapCount = 0
    @State private var showDevMenu = false

    var body: some View {
        ZStack {
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

            VStack {
                HStack {
                    Spacer()
                    Color.clear
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            devMenuTapCount += 1
                            if devMenuTapCount >= 5 {
                                devMenuTapCount = 0
                                showDevMenu = true
                            }
                        }
                }
                Spacer()
            }
        }
        .task {
            await AppState.shared.refresh()
        }
        .sheet(isPresented: $showDevMenu) {
            DevMenuView()
        }
    }
}
