//
//  ContentView.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 8/25/26.
//

import SwiftUI
import CoreLocation
import AuthenticationServices
import GoogleSignIn

struct ContentView: View {
    @StateObject private var locationManager = LocationManager.shared
    @State private var freshnessLog: [String] = []
    @State private var pairingCode: String = ""
    @State private var enteredCode: String = ""
    @State private var pairingStatus: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Location status: \(statusText)")

            Button("Request Location Permission") {
                locationManager.requestPermission()
            }
            Button("Upgrade to Always") {
                locationManager.requestAlwaysPermission()
            }
            Button("Save Test Token") {
                SessionStore.save("test-jwt-12345")
            }
            Button("Load Test Token") {
                print("Loaded: \(SessionStore.load() ?? "nothing found")")
            }
            Button("Clear Test Token") {
                SessionStore.clear()
            }
            Button("Get My Location") {
                locationManager.requestLocation()
            }
            Text(locationText)

            Button("Start Background Tracking") {
                locationManager.startSignificantLocationChanges()
            }
            
            Text(locationManager.postStatus)
            
            Button("Clear Freshness Log") {
                UserDefaults.standard.removeObject(forKey: "freshnessLog")
                freshnessLog = []
            }
            Button("Refresh Freshness Log (\(freshnessLog.count) entries)") {
                freshnessLog = UserDefaults.standard.stringArray(forKey: "freshnessLog") ?? []
            }

            List(freshnessLog, id: \.self) { entry in
                Text(entry)
                    .font(.caption)
            }
            
            
            Button("Create Pairing Code") {
                Task {
                    if let code = await createPairingCode() {
                        pairingCode = code
                    }
                }
            }
            Text(pairingCode.isEmpty ? "No code yet" : "Your code: \(pairingCode)")

            TextField("Enter partner's code", text: $enteredCode)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            Button("Join Pairing") {
                Task {
                    let success = await joinPairingCode(enteredCode)
                    pairingStatus = success ? "Paired!" : "Failed to pair"
                }
            }
            Text(pairingStatus)


            
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
        .onAppear {
            freshnessLog = UserDefaults.standard.stringArray(forKey: "freshnessLog") ?? []
        }
        .padding()
    }

    private var statusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "Not asked yet"
        case .authorizedWhenInUse:
            return "Granted (When In Use)"
        case .authorizedAlways:
            return "Granted (Always)"
        case .denied, .restricted:
            return "Denied"
        @unknown default:
            return "Unknown"
        }
    }

    
    private var locationText: String {
        guard let location = locationManager.lastLocation else {
            return "No location yet"
        }
        return "Lat: \(location.coordinate.latitude), Lng: \(location.coordinate.longitude)"
    }
}

#Preview {
    ContentView()
}
