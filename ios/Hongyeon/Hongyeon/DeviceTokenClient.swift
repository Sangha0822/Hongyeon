//
//  DeviceTokenClient.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 9/16/26.
//

import Foundation

private let deviceTokenKey = "deviceToken"

func saveDeviceToken(_ token: String) {
    UserDefaults.standard.set(token, forKey: deviceTokenKey)
    registerDeviceTokenIfReady()
}

func registerDeviceTokenIfReady() {
    guard let deviceToken = UserDefaults.standard.string(forKey: deviceTokenKey),
          let sessionToken = SessionStore.load() else { return }

    Task {
        let url = URL(string: "https://hongyeon-api.onrender.com/device-token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["token": deviceToken])

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            print("Device token registration status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        } catch {
            print("Device token registration failed: \(error.localizedDescription)")
        }
    }
}

// On sign-out: asks the server to stop sending this account's pushes to this device.
func unregisterDeviceToken() async {
    guard let deviceToken = UserDefaults.standard.string(forKey: deviceTokenKey),
          let sessionToken = SessionStore.load() else { return }

    let url = URL(string: "https://hongyeon-api.onrender.com/device-token/\(deviceToken)")!
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")

    do {
        let (_, response) = try await URLSession.shared.data(for: request)
        print("Device token removal status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
    } catch {
        print("Device token removal failed: \(error.localizedDescription)")
    }
}
