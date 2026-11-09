//
//  OnboardingProgress.swift
//  Hongyeon
//

import SwiftUI

// Shows which of the four onboarding stages the user is in.
struct OnboardingProgress: View {
    let step: Int // 1 to 4

    private let stages = ["About you", "Account", "Partner", "Location"]

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(1...stages.count, id: \.self) { index in
                    Capsule()
                        .fill(index < step ? Theme.blush : index == step ? Theme.accent : Theme.line) // done, current, upcoming
                        .frame(width: 36, height: 3)
                }
            }

            Text("\(stages[step - 1]) · \(step) of \(stages.count)")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
        }
        // VoiceOver reads one sentence instead of four bars and a label.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(step) of \(stages.count): \(stages[step - 1])")
    }
}

#Preview {
    VStack(spacing: 32) {
        OnboardingProgress(step: 1)
        OnboardingProgress(step: 3)
    }
    .padding()
    .background(Theme.background)
}
