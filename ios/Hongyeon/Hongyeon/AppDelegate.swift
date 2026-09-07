//
//  AppDelegate.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 8/31/26.
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UIApplication.shared.registerForRemoteNotifications()
        LocationManager.shared.startSignificantLocationChanges()
        return true
    }
    

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs device token: \(tokenString)")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let receivedAt = Date()
        print("Received remote notification at \(receivedAt), app state: \(application.applicationState.rawValue)")

        Task {
            await fetchPartnerLocation(receivedAt: receivedAt)
            completionHandler(.newData)
        }
    }

    func fetchPartnerLocation(receivedAt: Date) async {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        displayFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        let koreaTime = displayFormatter.string(from: receivedAt)

        guard let url = URL(string: "https://hongyeon-api.onrender.com/location") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
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
}
