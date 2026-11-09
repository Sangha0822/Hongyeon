//
//  NameView.swift
//  Hongyeon
//

import SwiftUI

// Asks a new user's name before sign-in.
struct NameView: View {
    // Saved on the phone, not in the view: signing in replaces this whole screen stack,
    // and the name has to survive until it's saved to the account (Phase 6.4).
    @AppStorage("draftName") private var draftName = ""
    @State private var name = "" // what's being typed; saved to draftName on Continue
    @State private var goToSignIn = false
    @FocusState private var isNameFocused: Bool

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            CornerThreadDecoration()

            ScrollView {
                VStack(spacing: 12) {
                    OnboardingProgress(step: 1)

                    // Full screen width, so the thread runs off both edges.
                    NameTagArt(name: trimmedName)

                    VStack(spacing: 12) {
                        Text("What should we call you?")
                            .font(Theme.displayFont)
                            .foregroundColor(Theme.textPrimary)

                        Text("Just the name your person calls you.")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textSecondary)

                        TextField("Your name", text: $name)
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textPrimary)
                            .tint(Theme.accent) // red cursor; the nav tint is ink
                            .textContentType(.givenName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .submitLabel(.continue)
                            .onSubmit(continueToSignIn)
                            .focused($isNameFocused)
                            .padding()
                            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.line, lineWidth: 1)
                            )
                            .padding(.top, 20)
                    }
                    .multilineTextAlignment(.center)
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
            Button("Continue", action: continueToSignIn)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(trimmedName.isEmpty)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
        }
        // Opens the keyboard on arrival, and again when coming back from sign-in.
        // Waits for the slide-in to finish: focusing mid-animation opens the keyboard,
        // but SwiftUI misses the safe-area change and Continue stays hidden behind it.
        .task {
            if name.isEmpty {
                name = draftName // a name saved on an earlier visit
            }
            try? await Task.sleep(for: .milliseconds(500))
            isNameFocused = true
        }
        .navigationDestination(isPresented: $goToSignIn) {
            SignInView(isReturning: false)
        }
    }

    // Shared by the Continue button and the keyboard's return key.
    private func continueToSignIn() {
        guard !trimmedName.isEmpty else { return }
        draftName = trimmedName
        goToSignIn = true
    }
}

#Preview {
    NavigationStack {
        NameView()
    }
}

#Preview("Large text") {
    NavigationStack {
        NameView()
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}
