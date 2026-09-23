//
//  HomeView.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 9/23/26.
//

import SwiftUI

struct HomeView: View {
    @State private var lastActiveText = "Checking..."
    @State private var pairingStatus = ""

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("You're Connected!")
                    .font(Theme.titleFont)
                    .foregroundColor(Theme.accent)

                Text(lastActiveText)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textPrimary)

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
            if let updatedAt = await fetchPartnerLocationStatus() {
                let formatter = RelativeDateTimeFormatter()
                lastActiveText = "Partner last active \(formatter.localizedString(for: updatedAt, relativeTo: Date()))"
            } else {
                lastActiveText = "No location from your partner yet"
            }
        }
    }
}
