//
//  AnniversaryView.swift
//  Hongyeon
//

import SwiftUI

// The optional "when did your story begin?" step, between the name and sign-in.
struct AnniversaryView: View {
    // Saved on the phone, like the draft name: AppState sends it once sign-in finishes.
    @AppStorage(draftAnniversaryKey) private var draftAnniversary: String?
    // Starts from a day picked on an earlier visit (back to Name, then forward again).
    @State private var date: Date? = UserDefaults.standard.string(forKey: draftAnniversaryKey)
        .flatMap { anniversaryFormatter.date(from: $0) }
    @State private var goToSignIn = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            CornerThreadDecoration()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 12) {
                        OnboardingProgress(step: 1)

                        CalendarArt()
                            .frame(width: 150)

                        VStack(spacing: 12) {
                            Text("YOUR FIRST CHAPTER")
                                .font(Theme.captionFont.weight(.semibold))
                                .tracking(2)
                                .foregroundColor(Theme.textSecondary)

                            Text("When did your\nstory begin?")
                                .font(Theme.displayFont)
                                .foregroundColor(Theme.textPrimary)

                            Text("A day worth keeping close. This is optional.")
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textSecondary)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                        AnniversaryCalendar(selection: $date)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Theme.line, lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        Text("A small circle around a very big day.")
                            .font(Theme.handwrittenFont)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }

                VStack(spacing: 4) {
                    Button {
                        guard let date else { return }
                        draftAnniversary = anniversaryFormatter.string(from: date)
                        goToSignIn = true
                    } label: {
                        HStack(spacing: 10) {
                            Text("Continue")
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(date == nil)

                    Button("I’ll add this later") {
                        draftAnniversary = nil
                        goToSignIn = true
                    }
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.vertical, 10)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 8)
            }
        }
        // Pushed from the Name screen while its keyboard is still up; without this the
        // content squeezes above the keyboard, then slides down as it goes away.
        .ignoresSafeArea(.keyboard)
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavWordmark()
            }
        }
        .navigationDestination(isPresented: $goToSignIn) {
            SignInView(isReturning: false)
        }
    }
}

#Preview {
    NavigationStack {
        AnniversaryView()
    }
}
