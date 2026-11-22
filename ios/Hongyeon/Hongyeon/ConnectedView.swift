//
//  ConnectedView.swift
//  Hongyeon
//

import SwiftUI

// A short celebration shown once to both partners right after pairing.
struct ConnectedView: View {
    @ObservedObject private var appState = AppState.shared

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            CornerThreadDecoration()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 12) {
                        OnboardingProgress(step: 3)

                        PairingThreadArt()
                            .padding(.vertical, 8)

                        VStack(spacing: 12) {
                            Text("You’re connected.")
                                .font(Theme.displayFont)
                                .foregroundColor(Theme.textPrimary)

                            Text("Two ends. One beginning.")
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textSecondary)

                            HStack(spacing: 14) {
                                Text(appState.displayName ?? "You")
                                ThreadHeart()
                                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                                    .frame(width: 36, height: 19)
                                    .accessibilityHidden(true)
                                Text(appState.partnerName ?? "Your partner")
                            }
                            .font(Theme.taglineFont)
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .padding(.top, 16)

                            Text("No matter how far, never really apart.")
                                .font(Theme.handwrittenFont)
                                .foregroundColor(Theme.textSecondary)
                                .padding(.top, 8)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    }
                    .padding(.top, 8)
                }

                VStack(spacing: 12) {
                    Button {
                        appState.justConnected = false
                    } label: {
                        HStack(spacing: 10) {
                            Text("Continue")
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Text("A connection that belongs only to you.")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavWordmark()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ConnectedView()
    }
}
