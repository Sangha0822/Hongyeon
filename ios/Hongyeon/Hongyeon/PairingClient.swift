//
//  PairingClient.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 9/11/26.
//

import Foundation

// A pairing code as the server describes it. The app shows it as "HY-" + code.
struct PairingCodeInfo {
    let code: String
    let expiresAt: Date

    var displayCode: String { "HY-\(code)" }
}

// Reads {"code": ..., "expires_at": ...} from the server; nil when either is missing or null.
private func pairingCodeInfo(from data: Data) -> PairingCodeInfo? {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let code = json["code"] as? String,
          let expiresText = json["expires_at"] as? String else { return nil }

    // The server sends microseconds ("...:54.142213+00:00"), which the ISO 8601 parser
    // doesn't accept, so the fraction is dropped before parsing.
    let withoutFraction = expiresText.replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression)
    guard let expiresAt = ISO8601DateFormatter().date(from: withoutFraction) else { return nil }
    return PairingCodeInfo(code: code, expiresAt: expiresAt)
}

// Makes a new code, replacing any earlier one.
func createPairingCode() async -> PairingCodeInfo? {
    guard let token = SessionStore.load() else { return nil }
    let url = URL(string: "https://hongyeon-api.onrender.com/pairing/create")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    do {
        let (data, _) = try await URLSession.shared.data(for: request)
        return pairingCodeInfo(from: data)
    } catch {
        print("Create pairing code failed: \(error.localizedDescription)")
        return nil
    }
}

// The code this user already has, or nil when they have none that is still valid.
// Throws when the server couldn't be asked, so "no code" and "couldn't check" stay different.
func fetchPairingCode() async throws -> PairingCodeInfo? {
    guard let token = SessionStore.load() else { return nil }
    let url = URL(string: "https://hongyeon-api.onrender.com/pairing/code")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await URLSession.shared.data(for: request)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }
    return pairingCodeInfo(from: data)
}

// How a join attempt ended.
enum JoinResult {
    case joined
    // errorCode is the server's fixed code (e.g. "own_code"), or nil when the server couldn't be reached.
    case failed(errorCode: String?)
}

func joinPairingCode(_ code: String) async -> JoinResult {
    guard let token = SessionStore.load() else { return .failed(errorCode: nil) }
    let url = URL(string: "https://hongyeon-api.onrender.com/pairing/join")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.httpBody = try? JSONSerialization.data(withJSONObject: ["code": code])

    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        if (response as? HTTPURLResponse)?.statusCode == 200 {
            await AppState.shared.refresh()
            return .joined
        }
        // Failures look like {"detail": {"code": "own_code", "message": "..."}}.
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        let detail = json?["detail"] as? [String: Any]
        return .failed(errorCode: detail?["code"] as? String ?? "unknown")
    } catch {
        print("Join pairing code failed: \(error.localizedDescription)")
        return .failed(errorCode: nil)
    }
}

func unpairPartner() async -> Bool {
    guard let token = SessionStore.load() else { return false }
    let url = URL(string: "https://hongyeon-api.onrender.com/pairing/unpair")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    do {
        let (_, response) = try await URLSession.shared.data(for: request)
        let success = (response as? HTTPURLResponse)?.statusCode == 200
        if success {
            // This phone asked for it, so it shouldn't be told "your partner disconnected".
            UserDefaults.standard.removeObject(forKey: wasPairedKey)
            await AppState.shared.refresh()
        }
        return success

    } catch {
        print("Unpair failed: \(error.localizedDescription)")
        return false
    }
}

