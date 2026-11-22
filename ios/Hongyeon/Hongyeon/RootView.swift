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
    @Environment(\.scenePhase) private var scenePhase
    @State private var devMenuTapCount = 0
    @State private var showDevMenu = false

    var body: some View {
        ZStack {
            Group {
                switch appState.status {
                case .checking, .unreachable:
                    LaunchView(isUnreachable: appState.status == .unreachable)
                case .signedOut:
                    NavigationStack {
                        WelcomeView()
                    }
                    .tint(Theme.textPrimary) // ink back chevrons; red stays for actions
                case .needsName:
                    NavigationStack {
                        NameView(isMissingName: true)
                    }
                case .unpaired:
                    NavigationStack {
                        PartnerChoiceView()
                    }
                    .tint(Theme.textPrimary)
                case .paired:
                    if appState.justConnected {
                        NavigationStack {
                            ConnectedView()
                        }
                    } else if locationManager.authorizationStatus == .notDetermined || locationManager.justDenied {
                        NavigationStack {
                            LocationOnboardingView()
                        }
                    } else {
                        HomeView()
                    }
                }
            }
            // Screens fade into each other instead of cutting when the account status changes.
            .animation(.easeInOut(duration: 0.3), value: appState.status)

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
        // Coming back to the app re-checks the account, so a change made while it was in the
        // background (like the partner disconnecting) shows even if no push arrived.
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await AppState.shared.refresh() }
            }
        }
        .sheet(isPresented: $showDevMenu) {
            DevMenuView()
        }
    }
}
