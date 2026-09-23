//
//  PairingView.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 9/20/26.
//

import SwiftUI

struct PairingView: View {
    @State private var pairingCode: String = ""
    @State private var enteredCode: String = ""
    @State private var pairingStatus: String = ""

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("Invite your partner!")
                    .font(Theme.titleFont)
                    .foregroundColor(Theme.accent)

                Text("Share your code, or enter theirs, to connect.")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textPrimary)

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("My Code")
                            .font(Theme.bodyFont.weight(.semibold))
                            .foregroundColor(Theme.accent)

                        HStack {
                            Text(pairingCode.isEmpty ? "Tap Create Code" : pairingCode)
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textPrimary)

                            Spacer()

                            if !pairingCode.isEmpty {
                                Button {
                                    UIPasteboard.general.string = pairingCode
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(Theme.accent)
                                }

                                ShareLink(item: pairingCode) {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(Theme.accent)
                                }
                            }
                        }
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
                        )
                    }

                    Button("Create Pairing Code") {
                        Task {
                            if let code = await createPairingCode() {
                                pairingCode = code
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Rectangle()
                        .fill(Theme.accent.opacity(0.3))
                        .frame(height: 1)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Got your partner's code?")
                            .font(Theme.bodyFont.weight(.semibold))
                            .foregroundColor(Theme.accent)

                        TextField("Enter partner's code", text: $enteredCode)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button("Join Pairing") {
                        Task {
                            let success = await joinPairingCode(enteredCode)
                            pairingStatus = success ? "Paired!" : "Failed to pair"
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    if !pairingStatus.isEmpty {
                        Text(pairingStatus)
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textPrimary)
                    }
                }
                .padding(24)
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)

                Spacer()
            }
            .padding(.horizontal, 32)
        }
    }
}
