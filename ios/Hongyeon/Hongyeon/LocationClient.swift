//
//  LocationClient.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 9/18/26.
//

import Foundation
import CoreLocation

func postLocation(_ location: CLLocation) async -> String {
    guard let token = SessionStore.load() else {
        return "Not signed in"
    }

    let url = URL(string: "https://hongyeon-api.onrender.com/location")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let body: [String: Double] = [
        "lat": location.coordinate.latitude,
        "lng": location.coordinate.longitude
    ]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    do {
        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            return "Sent successfully!"
        } else {
            return "Server error"
        }
    } catch {
        return "Network error: \(error.localizedDescription)"
    }
}

func fetchPartnerLocationStatus() async -> Date? {
    guard let token = SessionStore.load() else { return nil }

    let url = URL(string: "https://hongyeon-api.onrender.com/location")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    do {
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        guard let updatedAtString = json["updated_at"] as? String else { return nil }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return isoFormatter.date(from: updatedAtString)
    } catch {
        print("Failed to fetch partner location status: \(error.localizedDescription)")
        return nil
    }
}


func fetchPartnerLocation(receivedAt: Date) async {
    let displayFormatter = DateFormatter()
    displayFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    displayFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
    let koreaTime = displayFormatter.string(from: receivedAt)

    guard let token = SessionStore.load() else {
        logFreshnessEntry("FAILURE at \(koreaTime) KST: not signed in")
        return
    }

    guard let url = URL(string: "https://hongyeon-api.onrender.com/location") else { return }
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    do {
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        print("Fetched partner location: \(json)")

        if let updatedAtString = json["updated_at"] as? String {
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let updatedAt = isoFormatter.date(from: updatedAtString) {
                let elapsed = receivedAt.timeIntervalSince(updatedAt)
                print("Time elapsed since the location was posted: \(elapsed) seconds")
                logFreshnessEntry("SUCCESS at \(koreaTime) KST: \(String(format: "%.2f", elapsed))s elapsed")
            }
        }
    } catch {
        print("Failed to fetch partner location: \(error.localizedDescription)")
        logFreshnessEntry("FAILURE at \(koreaTime) KST: \(error.localizedDescription)")
    }
}

func logFreshnessEntry(_ entry: String) {
    var log = UserDefaults.standard.stringArray(forKey: "freshnessLog") ?? []
    log.append(entry)
    UserDefaults.standard.set(log, forKey: "freshnessLog")
}
