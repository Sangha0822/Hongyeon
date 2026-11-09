//
//  WelcomeView.swift
//  Hongyeon
//

import SwiftUI

// First screen for anyone who isn't signed in.
struct WelcomeView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 6) {
                    Text("Hongyeon")
                        .font(Theme.heroWordmarkFont)
                        .foregroundColor(Theme.textPrimary)

                    ThreadHeartArt()
                        .frame(width: 180)
                        .padding(.vertical, 16)

                    Text("However far, the thread holds.")
                        .font(Theme.taglineFont)
                        .foregroundColor(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                }

                // Keeps the buttons close to the content instead of pinned far below it.
                Spacer(minLength: 40)
                    .frame(maxHeight: 120)

                VStack(spacing: 8) {
                    NavigationLink {
                        NameView()
                    } label: {
                        Text("Get started")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    NavigationLink {
                        SignInView(isReturning: true)
                    } label: {
                        Text("I already have an account")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textSecondary)
                            .frame(minHeight: 44)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        // Welcome has no text field. Without this, swiping back from the Name screen while
        // its keyboard is still up squeezes Welcome above the keyboard, then slides it down.
        .ignoresSafeArea(.keyboard)
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
    }
}

#Preview("Large text") {
    NavigationStack {
        WelcomeView()
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}
