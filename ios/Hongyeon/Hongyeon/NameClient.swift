//
//  NameClient.swift
//  Hongyeon
//

import Foundation

// Where NameView keeps the typed name until it's saved to the account.
let draftNameKey = "draftName"

// Saves the signed-in user's display name. Returns whether the server accepted it.
func saveName(_ name: String) async -> Bool {
    guard let sessionToken = SessionStore.load() else { return false }

    let url = URL(string: "https://hongyeon-api.onrender.com/me/name")!
    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
    request.httpBody = try? JSONSerialization.data(withJSONObject: ["display_name": name])

    do {
        let (_, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        print("Save name status: \(statusCode)")
        return statusCode == 200
    } catch {
        print("Save name failed: \(error.localizedDescription)")
        return false
    }
}
