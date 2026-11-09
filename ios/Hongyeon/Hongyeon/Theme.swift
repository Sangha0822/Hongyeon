//
//  Theme.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 9/19/26.
//

import SwiftUI

enum Theme {
    // "Hongsil" palette: the red thread is the only saturated color in the app.
    static let accent = Color(hex: 0xB74650)         // "thread" dusty rose: buttons, highlights
    static let background = Color(hex: 0xF8F3EC)     // "paper": screen background
    static let cardBackground = Color(hex: 0xFFFCF7) // "surface": cards, inputs
    static let textPrimary = Color(hex: 0x2E2624)    // "ink": main text
    static let textSecondary = Color(hex: 0x6B605A)  // "muted": hints, captions
    static let line = Color(hex: 0xE7DCD1)           // borders, dividers
    static let blush = Color(hex: 0xD98C8D)          // decoration only, too light for text
    static let blossom = Color(hex: 0xF6D6D5)        // soft rose tint for fills

    // Brand fonts
    static let wordmarkFont = Font.custom("Caveat-Regular", fixedSize: 34)                              // "Hongyeon" logo, never scales
    static let heroWordmarkFont = Font.custom("Caveat-Regular", fixedSize: 72)                          // large logo on the Welcome screen
    static let displayFont = Font.custom("CormorantGaramond-Medium", size: 34, relativeTo: .largeTitle) // screen headlines
    static let taglineFont = Font.custom("CormorantGaramond-Medium", size: 24, relativeTo: .title2)     // short serif lines under a title
    static let handwrittenFont = Font.custom("Caveat-Regular", size: 22, relativeTo: .title3)          // small handwritten accents

    // UI fonts (system)
    static let titleFont = Font.system(.title2, weight: .semibold)
    static let bodyFont = Font.system(.body)
    static let captionFont = Font.system(.footnote)
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled // false inside .disabled(true)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.bodyFont.weight(.semibold))
            .foregroundColor(.white)
            .padding()
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .background(Theme.accent)
            .cornerRadius(12)
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1.0) : 0.4)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
