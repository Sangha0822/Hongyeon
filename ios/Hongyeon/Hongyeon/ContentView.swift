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
            Button("Get My Location") {
                locationManager.requestLocation()
            }
            Text(locationText)
            Button("Send Location") {
                Task {
                    await locationManager.sendLocation()
                }
            }

            Text(locationManager.postStatus)
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
