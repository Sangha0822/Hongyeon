//
//  LocationManager.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 8/25/26.
//

import Foundation
import CoreLocation
import Combine



class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    @Published var lastLocation: CLLocation?

    func requestLocation() {
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    @Published var postStatus: String = ""

    func sendLocation() async {
        guard let location = lastLocation else {
            postStatus = "No location yet"
            return
        }

        let url = URL(string: "https://hongyeon-api.onrender.com/location")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Double] = [
            "lat": location.coordinate.latitude,
            "lng": location.coordinate.longitude
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                postStatus = "Sent successfully!"
            } else {
                postStatus = "Server error"
            }
        } catch {
            postStatus = "Network error: \(error.localizedDescription)"
        }
    }

}
