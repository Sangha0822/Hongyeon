//
//  AppState.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 9/19/26.
//

import Foundation
import Combine

enum AccountStatus {
    case checking     // launch: waiting for the server's answer
    case signedOut    // no token, or the server rejected it (401)
    case unpaired
    case paired
    case unreachable  // couldn't reach the server, and there's no earlier answer
}

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()

    @Published var status: AccountStatus = .checking

    func refresh() async {
        guard let token = SessionStore.load() else {
            status = .signedOut
            print("AppState refreshed: signedOut (no token)")
            return
        }

        let url = URL(string: "https://hongyeon-api.onrender.com/me")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode

            if statusCode == 401 {
                // The saved session expired or is invalid - sign out instead of pretending.
                SessionStore.clear()
                status = .signedOut
            } else if statusCode == 200 {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let paired = json?["paired"] as? Bool ?? false
                status = paired ? .paired : .unpaired
            } else {
                keepStatusOrMarkUnreachable()
            }
        } catch {
            print("Failed to refresh app state: \(error.localizedDescription)")
            keepStatusOrMarkUnreachable()
        }
        print("AppState refreshed: \(status)")
    }

    // One failed request shouldn't replace an answer we already have
    // (e.g. a silent push waking the app with a weak connection).
    private func keepStatusOrMarkUnreachable() {
        if status == .checking {
            status = .unreachable
        }
    }
}
