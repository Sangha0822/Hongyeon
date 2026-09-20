//
//  SignInView.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 9/19/26.
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn

struct SignInView: View {
    @State private var isSigningIn = false
    @State private var loadingMessage = "Signing you in..."

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("Hongyeon")
                    .font(.custom("Bradley Hand", size: 44))
                    .foregroundColor(Theme.accent)

                Text("Stay close, no matter the distance.")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                VStack(spacing: 24) {
                    Button("Sign in with Google") {
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
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(height: 50)
                    .disabled(isSigningIn)

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
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(isSigningIn)
                }
                .opacity(isSigningIn ? 0.3 : 1.0)
                .frame(height: 130)

                Spacer()
            }
            .padding(.horizontal, 32)

            if isSigningIn {
                VStack(spacing: 12) {
                    ProgressView()
                    Text(loadingMessage)
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textPrimary)
                }
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
}
