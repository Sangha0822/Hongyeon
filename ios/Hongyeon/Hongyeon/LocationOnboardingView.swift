//
//  LocationOnboardingView.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 9/11/26.
//

import SwiftUI

// Shown once, before iOS's own location popup, while permission has never been asked.
// One "Continue" and no "Not now": Apple's guidance for a screen in front of a permission
// popup, and the popup itself is where the person says yes or no.
struct LocationOnboardingView: View {
    @ObservedObject private var locationManager = LocationManager.shared
    @ObservedObject private var appState = AppState.shared

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            CornerThreadDecoration()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 12) {
                        OnboardingProgress(step: 4)

                        LocationPinsArt(partnerName: appState.partnerName ?? "them")
                            .frame(width: 250)
                            .padding(.vertical, 8)

                        VStack(spacing: 12) {
                            Text("DISTANCE IS JUST A NUMBER")
                                .font(Theme.captionFont.weight(.semibold))
                                .tracking(2)
                                .foregroundColor(Theme.textSecondary)

                            Text("A little closer,\nwherever you are.")
                                .font(Theme.displayFont)
                                .foregroundColor(Theme.textPrimary)

                            Text("Share your location to see your distance and the direction to each other.")
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textSecondary)
                        }
                        .multilineTextAlignment(.center)

                        VStack(alignment: .leading, spacing: 20) {
                            promiseRow(icon: "lock",
                                       title: "Only for your connected partner.",
                                       detail: "Never public. Never shared with anyone else.")
                            promiseRow(icon: "mappin.and.ellipse",
                                       title: "Always your choice.",
                                       detail: "Turn it off anytime in Settings.")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                }

                if locationManager.justDenied {
                    deniedActions
                } else {
                    Button {
                        locationManager.requestPermission()
                    } label: {
                        HStack(spacing: 10) {
                            Text("Continue")
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavWordmark()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // After a "Don't Allow": accept the answer, and leave a quiet way back for a mis-tap.
    // iOS won't show its popup again, so that way back is Settings.
    private var deniedActions: some View {
        VStack(spacing: 12) {
            Text("That’s okay. Your thread is still connected. You can turn location on in Settings anytime.")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.line, lineWidth: 1)
                )

            Button {
                locationManager.justDenied = false
            } label: {
                HStack(spacing: 10) {
                    Text("Continue Without Sharing")
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(Theme.bodyFont)
            .foregroundColor(Theme.textSecondary)
            .padding(.vertical, 6)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 8)
    }

    private func promiseRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(Theme.accent)
                .frame(width: 22)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textPrimary)
                Text(detail)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        LocationOnboardingView()
    }
}
