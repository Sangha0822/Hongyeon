//
//  EnterCodeView.swift
//  Hongyeon
//

import SwiftUI

// "I have a code": the joiner types their partner's invitation code and connects.
struct EnterCodeView: View {
    @State private var entered = "" // only the six code characters; "HY-" is shown, never typed
    @State private var isJoining = false
    @State private var errorMessage: String?
    @FocusState private var isFieldFocused: Bool

    private var canJoin: Bool {
        entered.count == 6 && !isJoining
    }

    // Keeps only what a code can contain. A pasted "HY-K7MQ2X" or "k7 mq2x" becomes "K7MQ2X".
    private func cleaned(_ text: String) -> String {
        var code = text.uppercased()
        if code.hasPrefix("HY-") {
            code.removeFirst(3)
        }
        return String(code.filter { $0.isLetter || $0.isNumber }.prefix(6))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            CornerThreadDecoration()

            ScrollView {
                VStack(spacing: 12) {
                    OnboardingProgress(step: 3)

                    LooseEndsArt()
                        .padding(.vertical, 8)

                    VStack(spacing: 12) {
                        Text("Find your other end.")
                            .font(Theme.displayFont)
                            .foregroundColor(Theme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Enter the invitation code from your partner.")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("YOUR PARTNER’S INVITATION CODE")
                                .font(Theme.captionFont.weight(.semibold))
                                .tracking(1.5)
                                .foregroundColor(Theme.textSecondary)

                            // "HY-" is fixed text in front of the field, so only the six characters are typed.
                            HStack(spacing: 0) {
                                Text("HY-")
                                    .foregroundColor(Theme.textSecondary)

                                TextField("______", text: $entered)
                                    .foregroundColor(Theme.textPrimary)
                                    .tint(Theme.accent)
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled()
                                    .keyboardType(.asciiCapable)
                                    .submitLabel(.join)
                                    .onSubmit(join)
                                    .focused($isFieldFocused)
                                    .frame(width: 136) // room for six characters, so "HY-" + code stays centered
                            }
                            .font(.system(size: 24, weight: .medium))
                            .tracking(4)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(errorMessage == nil ? Theme.line : Theme.accent, lineWidth: 1)
                            )
                            // Tapping anywhere in the box, including on "HY-", puts the cursor in the field.
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isFieldFocused = true
                            }
                            .onChange(of: entered) { _, newValue in
                                errorMessage = nil // typing again clears the last error
                                let code = cleaned(newValue)
                                if code != newValue {
                                    entered = code
                                }
                            }
                        }
                        .padding(.top, 16)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.accent)
                                .multilineTextAlignment(.center)
                        }

                        Label("A private space. Only for two.", systemImage: "lock")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textSecondary)
                            .padding(.top, 24)
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.top, 8)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavWordmark()
            }
        }
        // The keyboard counts as part of the safe area, so this button rides up above it.
        .safeAreaInset(edge: .bottom) {
            Button(action: join) {
                HStack(spacing: 10) {
                    Text(isJoining ? "Connecting…" : "Connect our thread")
                    if !isJoining {
                        Image(systemName: "heart")
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canJoin)
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
        }
        // Opens the keyboard once the slide-in has finished (focusing mid-animation
        // leaves the button hidden behind the keyboard).
        .task {
            try? await Task.sleep(for: .milliseconds(500))
            isFieldFocused = true
        }
    }

    private func join() {
        guard canJoin else { return }
        isJoining = true
        errorMessage = nil

        Task {
            let result = await joinPairingCode(entered)
            // On success AppState is now "paired" and RootView moves on by itself.
            if case .failed(let errorCode) = result {
                errorMessage = message(for: errorCode)
                if errorCode == "already_paired" {
                    await AppState.shared.refresh()
                }
            }
            isJoining = false
        }
    }

    // The server's fixed error codes, turned into words for people.
    private func message(for errorCode: String?) -> String {
        switch errorCode {
        case "code_not_found":
            return "That code doesn’t work. It may have expired, so ask your partner for a new one."
        case "own_code":
            return "That’s your own code. Send it to your partner instead."
        case "partner_already_paired":
            return "Whoever made this code is already connected with someone else."
        case "already_paired":
            return "You’re already connected."
        case nil:
            return "Couldn’t reach Hongyeon. Check your connection and try again."
        default:
            return "Something went wrong. Please try again."
        }
    }
}

#Preview {
    NavigationStack {
        EnterCodeView()
    }
}
