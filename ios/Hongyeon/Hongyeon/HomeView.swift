//
//  HomeView.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 9/23/26.
//

import SwiftUI
import CoreLocation

struct HomeView: View {
    @ObservedObject private var locationManager = LocationManager.shared
    @State private var lastActiveText = "Checking..."
    @State private var partnerStatus: PartnerLocationStatus? = nil
    @State private var pairingStatus = ""
    @State private var displayedBearing: Double = 0

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("You're Connected!")
                    .font(Theme.titleFont)
                    .foregroundColor(Theme.accent)

                VStack(spacing: 16) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 56))
                        .foregroundColor(Theme.accent)
                        .rotationEffect(.degrees(displayedBearing))
                        .opacity(bearingDegrees != nil ? 1 : 0)
                        .onChange(of: bearingDegrees) { _, newValue in
                            if let newValue {
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    displayedBearing = newValue
                                }
                            }
                        }

                    Text(distanceText)
                        .font(Theme.bodyFont.weight(.semibold))
                        .foregroundColor(Theme.textPrimary)

                    Text(lastActiveText)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textPrimary.opacity(0.6))
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        Theme.cardBackground
                        TexturedBackground()
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)

                Button("Refresh") {
                    Task {
                        await refreshPartnerStatus()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())

                Spacer()

                Button("Disconnect Pairing") {
                    Task {
                        let success = await unpairPartner()
                        pairingStatus = success ? "Disconnected" : "Failed to disconnect"
                    }
                }
                .buttonStyle(PrimaryButtonStyle())

                if !pairingStatus.isEmpty {
                    Text(pairingStatus)
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textPrimary)
                }

                Spacer()
            }
            .padding(.horizontal, 32)
            }
        .task {
            await refreshPartnerStatus()
        }
    }


    private func refreshPartnerStatus() async {
        locationManager.requestLocation()

        if let status = await fetchPartnerLocationStatus() {
            partnerStatus = status
            if let updatedAt = status.updatedAt {
                let formatter = RelativeDateTimeFormatter()
                lastActiveText = "Partner last active \(formatter.localizedString(for: updatedAt, relativeTo: Date()))"
            } else {
                lastActiveText = "No location from your partner yet"
            }
        } else {
            lastActiveText = "No location from your partner yet"
        }
    }

    private var distanceText: String {
        guard let partnerStatus = partnerStatus else { return "" }
        guard let myLocation = locationManager.lastLocation else { return "Waiting for your location..." }

        let partnerLocation = CLLocation(latitude: partnerStatus.lat, longitude: partnerStatus.lng)
        let distanceMeters = myLocation.distance(from: partnerLocation)
        let measurement = Measurement(value: distanceMeters, unit: UnitLength.meters)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        return formatter.string(from: measurement) + " away"
    }
    
    private var bearingDegrees: Double? {
        guard let partnerStatus = partnerStatus, let myLocation = locationManager.lastLocation else { return nil }

        let lat1 = myLocation.coordinate.latitude * .pi / 180
        let lat2 = partnerStatus.lat * .pi / 180
        let deltaLon = (partnerStatus.lng - myLocation.coordinate.longitude) * .pi / 180

        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        let bearingRadians = atan2(y, x)
        let bearingDegrees = bearingRadians * 180 / .pi
        return (bearingDegrees + 360).truncatingRemainder(dividingBy: 360)
    }
}

struct TexturedBackground: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 10
            let dotSize: CGFloat = 1.5

            var x: CGFloat = 0
            while x < size.width {
                var y: CGFloat = 0
                while y < size.height {
                    let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                    context.fill(Path(ellipseIn: rect), with: .color(Theme.accent.opacity(0.08)))
                    y += spacing
                }
                x += spacing
            }
        }
    }
}
