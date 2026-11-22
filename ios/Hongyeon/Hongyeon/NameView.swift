//
//  NameView.swift
//  Hongyeon
//

import SwiftUI

// Asks for the user's name. New users see it before sign-in; a signed-in account
// that still has no name sees it again (isMissingName) before pairing.
struct NameView: View {
    var isMissingName = false

    // Saved on the phone, not in the view: signing in replaces this whole screen stack,
    // and the name has to survive until AppState saves it to the account.
    @AppStorage(draftNameKey) private var draftName = ""
    @State private var name = "" // what's being typed; saved to draftName on Continue
    @State private var goToAnniversary = false
    @State private var isSaving = false
    @State private var showsError = false
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
                    if !isMissingName {
                        OnboardingProgress(step: 1)
                    }

                    // Full screen width, so the thread runs off both edges.
                    NameTagArt(name: trimmedName)

                    VStack(spacing: 12) {
                        Text("What should we\ncall you?")
                            .font(Theme.displayFont)
                            .foregroundColor(Theme.textPrimary)

                        Text(isMissingName ? "Your account doesn’t have a name yet." : "Just the name your person calls you.")
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
                            .onSubmit(continueToNextStep)
                            .focused($isNameFocused)
                            .padding()
                            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.line, lineWidth: 1)
                            )
                            .padding(.top, 20)
                            // The server accepts at most 20 characters.
                            .onChange(of: name) { _, newValue in
                                if newValue.count > 20 {
                                    name = String(newValue.prefix(20))
                                }
                            }

                        if showsError {
                            Text("Couldn’t save your name. Please try again.")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.accent)
                        }
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
        // The first screen in a stack gets room for a large title by default;
        // inline keeps the content right under the wordmark.
        .navigationBarTitleDisplayMode(.inline)
        // The keyboard counts as part of the safe area, so this button rides up above it.
        .safeAreaInset(edge: .bottom) {
            Button("Continue", action: continueToNextStep)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(trimmedName.isEmpty || isSaving)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
        }
        // Opens the keyboard on arrival, and again when coming back from the next screen.
        // Waits for the slide-in to finish: focusing mid-animation opens the keyboard,
        // but SwiftUI misses the safe-area change and Continue stays hidden behind it.
        .task {
            if name.isEmpty {
                name = draftName // a name saved on an earlier visit
            }
            try? await Task.sleep(for: .milliseconds(500))
            isNameFocused = true
        }
        .navigationDestination(isPresented: $goToAnniversary) {
            AnniversaryView()
        }
    }

    // Shared by the Continue button and the keyboard's return key.
    private func continueToNextStep() {
        guard !trimmedName.isEmpty, !isSaving else { return }

        guard isMissingName else {
            draftName = trimmedName
            goToAnniversary = true
            return
        }

        // Already signed in: save straight to the account, then let AppState move on.
        isSaving = true
        showsError = false
        Task {
            if await saveName(trimmedName) {
                await AppState.shared.refresh()
            } else {
                showsError = true
            }
            isSaving = false
        }
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
