//
//  AppState.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 9/19/26.
//

import Foundation
import Combine

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isSignedIn: Bool = false
    @Published var isPaired: Bool = false

    func refresh() async {
        guard let token = SessionStore.load() else {
            isSignedIn = false
            isPaired = false
            print("AppState refreshed: isSignedIn=false, isPaired=false (no token)")
            return
        }
        isSignedIn = true

        let url = URL(string: "https://hongyeon-api.onrender.com/me")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            isPaired = json?["paired"] as? Bool ?? false
        } catch {
            print("Failed to refresh app state: \(error.localizedDescription)")
        }
        print("AppState refreshed: isSignedIn=\(isSignedIn), isPaired=\(isPaired)")
    }

}
