//
//  NavWordmark.swift
//  Hongyeon
//

import SwiftUI

// The small "Hongyeon" wordmark with its thread heart, centered in an onboarding screen's navigation bar.
struct NavWordmark: View {
    var body: some View {
        HStack(spacing: 2) {
            Text("Hongyeon")
                .font(Theme.wordmarkFont)
                .foregroundColor(Theme.textPrimary)
            ThreadHeart()
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                .frame(width: 36, height: 19)
                .accessibilityHidden(true)
        }
    }
}
