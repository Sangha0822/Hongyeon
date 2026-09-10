//
//  PairingClient.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 9/11/26.
//

import Foundation

func createPairingCode() async -> String? {
    guard let token = SessionStore.load() else { return nil }
    let url = URL(string: "https://hongyeon-api.onrender.com/pairing/create")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    do {
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["code"] as? String
    } catch {
        print("Create pairing code failed: \(error.localizedDescription)")
        return nil
    }
}

func joinPairingCode(_ code: String) async -> Bool {
    guard let token = SessionStore.load() else { return false }
    let url = URL(string: "https://hongyeon-api.onrender.com/pairing/join")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.httpBody = try? JSONSerialization.data(withJSONObject: ["code": code])

    do {
        let (_, response) = try await URLSession.shared.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode == 200
    } catch {
        print("Join pairing code failed: \(error.localizedDescription)")
        return false
    }
}
