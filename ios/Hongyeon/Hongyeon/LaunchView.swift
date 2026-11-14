//
//  LaunchView.swift
//  Hongyeon
//

import SwiftUI

// Shown while the app asks the server who the user is, or when it couldn't reach the server.
struct LaunchView: View {
    let isUnreachable: Bool
    @State private var isRetrying = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            // Mirrors WelcomeView's layout, so the wordmark sits in the same place
            // when this screen fades into Welcome.
            VStack(spacing: 0) {
                Spacer()

                Text("Hongyeon")
                    .font(Theme.heroWordmarkFont)
                    .foregroundColor(Theme.textPrimary)

                // The space Welcome's thread heart and tagline take.
                ZStack {
                    if isUnreachable && !isRetrying {
                        Text("We couldn't reach Hongyeon. Check your connection and try again.")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    } else {
                        ProgressView()
                            .tint(Theme.accent)
                    }
                }
                .frame(height: 169)

                Spacer(minLength: 40)
                    .frame(maxHeight: 120)

                // The space Welcome's two buttons take; Try again sits where Get started will.
                ZStack {
                    if isUnreachable && !isRetrying {
                        Button("Try again") {
                            Task {
                                isRetrying = true
                                await AppState.shared.refresh()
                                isRetrying = false
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .frame(height: 106, alignment: .top)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

#Preview("Checking") {
    LaunchView(isUnreachable: false)
}

#Preview("Unreachable") {
    LaunchView(isUnreachable: true)
}
