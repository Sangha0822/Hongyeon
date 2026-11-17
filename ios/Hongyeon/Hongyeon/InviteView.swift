//
//  InviteView.swift
//  Hongyeon
//

import SwiftUI

// "Share my code": shows this user's invitation code and waits for the partner to join.
struct InviteView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var info: PairingCodeInfo?
    @State private var isExpired = false
    @State private var isLoading = true
    @State private var justCopied = false
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            CornerThreadDecoration()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 12) {
                        OnboardingProgress(step: 3)

                        LooseEndsArt()
                            .padding(.vertical, 8)

                        VStack(spacing: 12) {
                            Text(isExpired ? "A fresh\ninvitation awaits." : "Your end is ready.")
                                .font(Theme.displayFont)
                                .foregroundColor(Theme.textPrimary)

                            Text(isExpired ? "This code has expired. Create a new one to connect." : "Share this invitation with your partner.")
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textSecondary)

                            if let info {
                                codeCard(info)
                                    .padding(.top, 12)

                                if isExpired {
                                    expiredFooter
                                } else {
                                    waitingFooter
                                }
                            } else if isLoading {
                                ProgressView()
                                    .tint(Theme.accent)
                                    .padding(.top, 40)
                            } else {
                                Text("Couldn’t create your invitation. Check your connection and try again.")
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.accent)
                                    .padding(.top, 20)

                                Button("Try again") {
                                    Task { await loadCode(forceNew: false) }
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            }
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
                    .padding(.bottom, 16)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavWordmark()
            }
        }
        // Runs while this screen is open and stops when it closes.
        .task {
            await loadCode(forceNew: false)

            // A silent push normally announces that the partner joined, but pushes can be
            // late or lost. Asking the server every few seconds makes sure this screen moves on:
            // once /me says "paired", AppState changes and RootView swaps the screen.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard let current = info, !isExpired else { continue }

                if current.expiresAt <= Date() {
                    isExpired = true
                    continue
                }

                await AppState.shared.refresh()
                // If the partner joined, AppState is now "paired" and this screen is on its way out.
                guard AppState.shared.status == .unpaired, !Task.isCancelled else { continue }

                // The server decides whether the code still works, not this phone's clock.
                // No code, or a different one (made on another device), means this one is dead.
                do {
                    let live = try await fetchPairingCode()
                    if live?.code != current.code {
                        isExpired = true
                    }
                } catch {
                    // Offline or a server hiccup: keep showing the code and check again next time.
                }
            }
        }
        .onDisappear {
            isPulsing = false
        }
    }

    // Reuses a code that is still valid, so one already sent to the partner keeps working.
    private func loadCode(forceNew: Bool) async {
        isLoading = true
        defer { isLoading = false }

        var loaded: PairingCodeInfo?
        if !forceNew {
            do {
                loaded = try await fetchPairingCode()
            } catch {
                // Couldn't check: don't make a new code, which would replace one already sent.
                return
            }
        }
        if loaded == nil {
            loaded = await createPairingCode()
        }
        if let loaded {
            info = loaded
            isExpired = false
        }
    }

    private func codeCard(_ info: PairingCodeInfo) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                Text("YOUR INVITATION CODE")
                    .font(Theme.captionFont.weight(.semibold))
                    .tracking(1.5)
                    .foregroundColor(Theme.textSecondary)

                Text(info.displayCode)
                    .font(.system(size: 30, weight: .medium))
                    .tracking(4)
                    .strikethrough(isExpired)
                    .foregroundColor(isExpired ? Theme.textSecondary : Theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(isExpired
                     ? "Expired · This code can no longer be used"
                     : "Expires \(info.expiresAt.formatted(.dateTime.month(.abbreviated).day().hour().minute())) · One use")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 16)

            Rectangle().fill(Theme.line).frame(height: 1)

            HStack(spacing: 0) {
                Button {
                    UIPasteboard.general.string = info.displayCode
                    justCopied = true
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        justCopied = false
                    }
                } label: {
                    Label(justCopied ? "Copied" : "Copy Code", systemImage: justCopied ? "checkmark" : "doc.on.doc")
                        .frame(maxWidth: .infinity, minHeight: 50)
                }

                Rectangle().fill(Theme.line).frame(width: 1, height: 50)

                ShareLink(item: "Join me on Hongyeon. My invitation code is \(info.displayCode).") {
                    Label("Share Invitation", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
            }
            .font(Theme.captionFont.weight(.medium))
            .foregroundColor(Theme.textPrimary)
            .disabled(isExpired)
            .opacity(isExpired ? 0.4 : 1)
        }
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.line, lineWidth: 1)
        )
    }

    private var waitingFooter: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 7, height: 7)
                    .opacity(isPulsing ? 0.3 : 1)
                    .onAppear {
                        guard !reduceMotion else { return }
                        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                            isPulsing = true
                        }
                    }
                Text("Waiting for your partner…")
            }
            Text("Your connection appears here when they accept.")
        }
        .font(Theme.captionFont)
        .foregroundColor(Theme.textSecondary)
        .padding(.top, 8)
    }

    private var expiredFooter: some View {
        VStack(spacing: 12) {
            Text("Invitation expired. Your thread is still here.")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)

            Button {
                Task { await loadCode(forceNew: true) }
            } label: {
                HStack(spacing: 10) {
                    Text("Create New Code")
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        InviteView()
    }
}
