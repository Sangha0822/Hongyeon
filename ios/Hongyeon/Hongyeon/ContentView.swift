//
//  ContentView.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 8/25/26.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        VStack(spacing: 20) {
            Text("Location status: \(statusText)")

            Button("Request Location Permission") {
                locationManager.requestPermission()
            }
        }
        .padding()
    }

    private var statusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "Not asked yet"
        case .authorizedWhenInUse, .authorizedAlways:
            return "Granted"
        case .denied, .restricted:
            return "Denied"
        @unknown default:
            return "Unknown"
        }
    }
}

#Preview {
    ContentView()
}
