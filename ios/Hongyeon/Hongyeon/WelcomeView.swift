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
                    .padding(.horizontal, 32)

                // Where the name comes from.
                Text("홍연 · 紅緣 · the red thread of fate")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.top, 10)

                // Two spacers below and one above: the content sits a third of the way down,
                // not in the dead center.
                Spacer()
                Spacer()

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
                            .font(Theme.bodyFont.weight(.medium))
                            .foregroundColor(Theme.textPrimary)
                            .frame(minHeight: 44)
                    }
                }
                .padding(.horizontal, 32)
            }
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
