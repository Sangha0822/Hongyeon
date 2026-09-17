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
    static let shared = LocationManager()
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
        guard let location = locations.last else { return }
        lastLocation = location
        Task {
            postStatus = await postLocation(location)
        }
    }


    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    @Published var postStatus: String = ""

    func requestAlwaysPermission() {
        manager.requestAlwaysAuthorization()
    }
    func startSignificantLocationChanges() {
        manager.startMonitoringSignificantLocationChanges()
    }
    
}
