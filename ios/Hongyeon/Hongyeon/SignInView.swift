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
    var body: some View {
        VStack(spacing: 20) {
            Button("Sign in with Google") {
                guard let rootViewController = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first?.windows.first?.rootViewController else {
                    return
                }

                GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
                    if let error = error {
                        print("Google sign-in failed: \(error.localizedDescription)")
                        return
                    }
                    if let idToken = result?.user.idToken?.tokenString {
                        Task {
                            await signIn(endpoint: "auth/google", identityToken: idToken)
                        }
                    }
                }
            }

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.email]
            } onCompletion: { result in
                switch result {
                case .success(let authorization):
                    if let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                       let identityTokenData = credential.identityToken,
                       let identityTokenString = String(data: identityTokenData, encoding: .utf8) {
                        Task {
                            await signIn(endpoint: "auth/apple", identityToken: identityTokenString)
                        }
                    }
                case .failure(let error):
                    print("Sign in with Apple failed: \(error.localizedDescription)")
                }
            }
            .frame(height: 50)
        }
        .padding()
    }
}
