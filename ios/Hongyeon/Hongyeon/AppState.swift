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
    case needsName    // signed in, but the account has no name yet
    case unpaired
    case paired
    case unreachable  // couldn't reach the server, and there's no earlier answer
}

// Set while this phone's account is paired, so a later "unpaired" that this phone didn't ask for
// can be recognised as the partner disconnecting, even across app launches.
let wasPairedKey = "wasPaired"

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()

    @Published var status: AccountStatus = .checking
    @Published var partnerDisconnected = false // shown once on the choice screen
    @Published var justConnected = false // shows "You're connected" once, right after pairing
    @Published var displayName: String?
    @Published var partnerName: String?

    func refresh() async {
        guard let token = SessionStore.load() else {
            status = .signedOut
            notePairingChange()
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
                let hasName = json?["display_name"] is String
                displayName = json?["display_name"] as? String
                partnerName = json?["partner_name"] as? String
                let draftName = UserDefaults.standard.string(forKey: draftNameKey) ?? ""

                if hasName {
                    // Never overwrite a name the account already has; the draft is just dropped.
                    UserDefaults.standard.removeObject(forKey: draftNameKey)
                    status = paired ? .paired : .unpaired
                } else if !draftName.isEmpty, await saveName(draftName) {
                    // A new user: the name typed before sign-in is now on the account.
                    UserDefaults.standard.removeObject(forKey: draftNameKey)
                    status = paired ? .paired : .unpaired
                } else {
                    status = .needsName
                }
            } else {
                keepStatusOrMarkUnreachable()
            }
        } catch {
            print("Failed to refresh app state: \(error.localizedDescription)")
            keepStatusOrMarkUnreachable()
        }
        notePairingChange()
        print("AppState refreshed: \(status)")
    }

    // Paired → unpaired without this phone asking for it means the partner disconnected.
    // unpairPartner() clears the note first, so the phone that tapped Disconnect sees nothing.
    private func notePairingChange() {
        let defaults = UserDefaults.standard
        switch status {
        case .paired:
            // Not paired the last time this phone checked, so the pairing just happened.
            if !defaults.bool(forKey: wasPairedKey) {
                justConnected = true
            }
            defaults.set(true, forKey: wasPairedKey)
            partnerDisconnected = false
        case .unpaired where defaults.bool(forKey: wasPairedKey):
            defaults.removeObject(forKey: wasPairedKey)
            partnerDisconnected = true
        case .signedOut:
            defaults.removeObject(forKey: wasPairedKey)
            partnerDisconnected = false
            justConnected = false
        default:
            break
        }
    }

    // One failed request shouldn't replace an answer we already have
    // (e.g. a silent push waking the app with a weak connection).
    private func keepStatusOrMarkUnreachable() {
        if status == .checking {
            status = .unreachable
        }
    }
}
