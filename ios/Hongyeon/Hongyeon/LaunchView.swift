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

            VStack(spacing: 16) {
                Text("Hongyeon")
                    .font(Theme.wordmarkFont)
                    .foregroundColor(Theme.textPrimary)

                if isUnreachable && !isRetrying {
                    Text("We couldn't reach Hongyeon. Check your connection and try again.")
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)

                    Button("Try again") {
                        Task {
                            isRetrying = true
                            await AppState.shared.refresh()
                            isRetrying = false
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                } else {
                    ProgressView()
                        .tint(Theme.accent)
                }
            }
            .padding(.horizontal, 32)
        }
    }
}

#Preview("Checking") {
    LaunchView(isUnreachable: false)
}

#Preview("Unreachable") {
    LaunchView(isUnreachable: true)
}
