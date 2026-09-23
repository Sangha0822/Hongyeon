//
//  ContentView.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 8/25/26.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager.shared
    @State private var freshnessLog: [String] = []

    var body: some View {
        VStack(spacing: 20) {
            Text("Location status: \(statusText)")

            Button("Request Location Permission") {
                locationManager.requestPermission()
            }
            Button("Upgrade to Always") {
                locationManager.requestAlwaysPermission()
            }
            Button("Save Test Token") {
                SessionStore.save("test-jwt-12345")
            }
            Button("Load Test Token") {
                print("Loaded: \(SessionStore.load() ?? "nothing found")")
            }
            Button("Clear Test Token") {
                SessionStore.clear()
            }
            Button("Get My Location") {
                locationManager.requestLocation()
            }
            Text(locationText)

            Button("Start Background Tracking") {
                locationManager.startSignificantLocationChanges()
            }
            
            Text(locationManager.postStatus)
            
            Button("Clear Freshness Log") {
                UserDefaults.standard.removeObject(forKey: "freshnessLog")
                freshnessLog = []
            }
            Button("Refresh Freshness Log (\(freshnessLog.count) entries)") {
                freshnessLog = UserDefaults.standard.stringArray(forKey: "freshnessLog") ?? []
            }

            List(freshnessLog, id: \.self) { entry in
                Text(entry)
                    .font(.caption)
            }
        }
        .onAppear {
            freshnessLog = UserDefaults.standard.stringArray(forKey: "freshnessLog") ?? []
        }
        .padding()
    }

    private var statusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "Not asked yet"
        case .authorizedWhenInUse:
            return "Granted (When In Use)"
        case .authorizedAlways:
            return "Granted (Always)"
        case .denied, .restricted:
            return "Denied"
        @unknown default:
            return "Unknown"
        }
    }

    
    private var locationText: String {
        guard let location = locationManager.lastLocation else {
            return "No location yet"
        }
        return "Lat: \(location.coordinate.latitude), Lng: \(location.coordinate.longitude)"
    }
}

#Preview {
    ContentView()
}
