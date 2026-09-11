//
//  LocationOnboardingView.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 9/11/26.
//


import SwiftUI

struct LocationOnboardingView: View {
    @ObservedObject var locationManager = LocationManager.shared

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Hongyeon shares your current location with your paired partner, so you can each see how far apart you are and which direction to head.")
                .font(.body)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)

            Text("Only your most recent location is ever stored — never a history of where you've been. Your phone reports location only when you meaningfully move, not through constant tracking, so it won't drain your battery.")
                .font(.body)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)

            Spacer()

            Button("Continue") {
                locationManager.requestPermission()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }
}
