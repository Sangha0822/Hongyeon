//
//  AnniversarySheet.swift
//  Hongyeon
//

import SwiftUI

// Sets the couple's date from Home when it was skipped during onboarding.
// The server writes it to both partners' accounts.
struct AnniversarySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var date: Date?
    @State private var isSaving = false
    @State private var showsError = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    CalendarArt()
                        .frame(width: 130)

                    Text("When did your\nstory begin?")
                        .font(Theme.displayFont)
                        .foregroundColor(Theme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("You’ll both see the days you’ve been together.")
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textSecondary)
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

                    if showsError {
                        Text("Couldn’t save your date. Please try again.")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.accent)
                    }
                }
                .padding(.top, 24)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 4) {
                Button(isSaving ? "Saving..." : "Save", action: save)
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(date == nil || isSaving)

                Button("Cancel") { dismiss() }
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.vertical, 10)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 8)
            .background(Theme.background)
        }
    }

    private func save() {
        guard let date else { return }
        isSaving = true
        showsError = false
        Task {
            if await saveAnniversary(anniversaryFormatter.string(from: date)) {
                await AppState.shared.refresh()
                dismiss()
            } else {
                showsError = true
            }
            isSaving = false
        }
    }
}

#Preview {
    AnniversarySheet()
}
