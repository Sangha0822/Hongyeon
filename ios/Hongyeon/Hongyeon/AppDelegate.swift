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
        saveDeviceToken(tokenString)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let receivedAt = Date()
        print("Received remote notification at \(receivedAt), app state: \(application.applicationState.rawValue)")

        Task {
            await AppState.shared.refresh()
            await fetchPartnerLocation(receivedAt: receivedAt)
            completionHandler(.newData)
        }
    }

}
