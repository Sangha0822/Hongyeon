//
//  SignInView.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 9/19/26.
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn

// The "Save your story" step: sign in with Apple or Google.
struct SignInView: View {
    // Returning users come from Welcome's "I already have an account", so they skip "About you"
    // and see no progress bar.
    let isReturning: Bool

    @State private var isSigningIn = false
    @State private var loadingMessage = "Signing you in..."

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            CornerThreadDecoration()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 12) {
                        if !isReturning {
                            OnboardingProgress(step: 2)
                        }

                        EnvelopeArt()
                            .frame(width: 170)
                            .padding(.vertical, 8)

                        Text(isReturning ? "Welcome back to your story." : "Let’s keep your story safe.")
                            .font(Theme.displayFont)
                            .foregroundColor(Theme.textPrimary)

                        Text(isReturning ? "Sign in to continue your connection." : "Create an account so your connection stays with you.")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textSecondary)

                        // While signing in, the loading message takes the buttons' place.
                        // The hidden buttons keep their space, so nothing else moves.
                        VStack(spacing: 12) {
                            appleButton
                            googleButton
                        }
                        .disabled(isSigningIn)
                        .opacity(isSigningIn ? 0 : 1)
                        .overlay {
                            if isSigningIn {
                                VStack(spacing: 12) {
                                    ProgressView()
                                    Text(loadingMessage)
                                        .font(Theme.bodyFont)
                                        .foregroundColor(Theme.textPrimary)
                                }
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: isSigningIn)
                        .padding(.top, 20)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                }

                Label("Only your latest location is kept. Never a history.", systemImage: "lock")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)
            }
        }
        // Pushed from the Name screen while its keyboard is still up; without this the
        // content squeezes above the keyboard, then slides down as it goes away.
        .ignoresSafeArea(.keyboard)
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavWordmark()
            }
        }
        .onChange(of: isSigningIn) { _, newValue in
            guard newValue else { return }
            loadingMessage = "Signing you in..."
            Task {
                try? await Task.sleep(for: .seconds(6))
                guard isSigningIn else { return }
                loadingMessage = "Almost there..."

                try? await Task.sleep(for: .seconds(13))
                guard isSigningIn else { return }
                loadingMessage = "Waking up the server, hang tight..."
            }
        }
    }

    // Apple's own button, so it always meets Apple's design rules.
    private var appleButton: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.email]
            isSigningIn = true
        } onCompletion: { result in
            switch result {
            case .success(let authorization):
                if let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                   let identityTokenData = credential.identityToken,
                   let identityTokenString = String(data: identityTokenData, encoding: .utf8) {
                    Task {
                        await signIn(endpoint: "auth/apple", identityToken: identityTokenString)
                        isSigningIn = false
                    }
                } else {
                    isSigningIn = false
                }
            case .failure(let error):
                print("Sign in with Apple failed: \(error.localizedDescription)")
                isSigningIn = false
            }
        }
        .signInWithAppleButtonStyle(.whiteOutline)
        .frame(height: 50)
        // Rounding the corners clips Apple's own outline there, so it's redrawn on top.
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black, lineWidth: 1)
        )
    }

    // A custom button that follows Google's branding rules: the official "G" logo,
    // a white fill, a grey border and "Sign in with Google".
    // GoogleLogo is a PNG: Google's SVGs use web-only gradients that Xcode can't draw.
    private var googleButton: some View {
        Button(action: signInWithGoogle) {
            HStack(spacing: 10) {
                Image("GoogleLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16) // matches the visual size of Apple's glyph
                    .offset(x: 3) // logo-to-text gap ~7pt, like Apple's button; the text doesn't move
                Text("Sign in with Google")
            }
            .font(.system(size: 19, weight: .medium))
            .foregroundColor(Color(hex: 0x1F1F1F))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: 0x747775), lineWidth: 1)
            )
        }
    }

    private func signInWithGoogle() {
        isSigningIn = true
        guard let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController else {
            isSigningIn = false
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                print("Google sign-in failed: \(error.localizedDescription)")
                isSigningIn = false
                return
            }
            guard let idToken = result?.user.idToken?.tokenString else {
                isSigningIn = false
                return
            }
            Task { @MainActor in
                await signIn(endpoint: "auth/google", identityToken: idToken)
                isSigningIn = false
            }
        }
    }
}

#Preview("New user") {
    NavigationStack {
        SignInView(isReturning: false)
    }
}

#Preview("Returning user") {
    NavigationStack {
        SignInView(isReturning: true)
    }
}
