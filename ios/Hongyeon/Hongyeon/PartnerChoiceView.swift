//
//  PartnerChoiceView.swift
//  Hongyeon
//

import SwiftUI

// The first screen for a signed-in user who isn't paired: invite a partner, or enter their code.
struct PartnerChoiceView: View {
    @State private var goToInvite = false
    @State private var checkedForCode = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            CornerThreadDecoration()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 12) {
                        OnboardingProgress(step: 3)

                        // Full screen width, so each end runs off its edge.
                        LooseEndsArt()
                            .padding(.vertical, 8)

                        VStack(spacing: 12) {
                            Text("Let’s connect our\nred thread.")
                                .font(Theme.displayFont)
                                .foregroundColor(Theme.textPrimary)

                            Text("Every thread has two ends.")
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textSecondary)

                            // "I Have a Code" still opens the old pairing screen until Phase 6.7.
                            VStack(spacing: 12) {
                                NavigationLink {
                                    InviteView()
                                } label: {
                                    // Text centered across the button, with a symbol at each edge.
                                    ZStack {
                                        Text("Invite Your Partner")
                                        HStack {
                                            Image(systemName: "heart")
                                            Spacer()
                                            Image(systemName: "arrow.right")
                                        }
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle())

                                Text("A private invitation, just for them.")
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.textSecondary)

                                HStack(spacing: 12) {
                                    Rectangle().fill(Theme.line).frame(height: 1)
                                    Text("already have an invitation?")
                                        .font(Theme.captionFont)
                                        .foregroundColor(Theme.textSecondary)
                                        .fixedSize()
                                    Rectangle().fill(Theme.line).frame(height: 1)
                                }
                                .padding(.vertical, 8)

                                NavigationLink {
                                    PairingView()
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "link")
                                        Text("I Have a Code")
                                    }
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            }
                            .padding(.top, 20)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    }
                    .padding(.top, 8)
                }

                Label("A private space. Only for two.", systemImage: "lock")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 32)

                // Pairing is required and nothing sits behind this screen, so this is the
                // only way out for someone who signed in with the wrong account.
                Button("Sign out") {
                    Task {
                        // While the session still exists, so the server knows whose token it is.
                        await unregisterDeviceToken()
                        SessionStore.clear()
                        await AppState.shared.refresh()
                    }
                }
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
                .underline()
                .frame(minHeight: 44)
                .padding(.bottom, 4)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavWordmark()
            }
        }
        // The first screen in a stack gets room for a large title by default;
        // inline keeps the content right under the wordmark.
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $goToInvite) {
            InviteView()
        }
        // Reopening the app with a code still waiting goes straight back to the invite screen.
        .task {
            guard !checkedForCode else { return }
            checkedForCode = true
            if (try? await fetchPairingCode()) != nil {
                goToInvite = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        PartnerChoiceView()
    }
}
