//
//  AuthClient.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 9/9/26.
//

import Foundation

func signIn(endpoint: String, identityToken: String) async {
    let url = URL(string: "https://hongyeon-api.onrender.com/\(endpoint)")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try? JSONSerialization.data(withJSONObject: ["identity_token": identityToken])

    do {
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let token = json?["token"] as? String {
            SessionStore.save(token)
        }
    } catch {
        print("Sign-in request failed: \(error.localizedDescription)")
    }
}
