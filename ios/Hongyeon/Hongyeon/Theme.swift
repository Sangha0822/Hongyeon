//
//  Theme.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 9/19/26.
//

import SwiftUI

enum Theme {
    static let accent = Color(hex: 0xB74650)         // "thread" red: buttons, highlights
    static let background = Color(hex: 0xFBF5EC)     // "paper": screen background
    static let cardBackground = Color(hex: 0xFFF9F1) // "surface": cards, inputs
    static let textPrimary = Color(hex: 0x75473F)    // "ink": main text
    static let textSecondary = Color(hex: 0x85625C)  // "muted": hints, captions
    static let line = Color(hex: 0xEADBD0)           // borders, dividers
    static let blush = Color(hex: 0xD98C8D)          // decoration only, too light for text
    static let blossom = Color(hex: 0xF6D6D5)        // soft pink fills

    static let titleFont = Font.system(.title, design: .rounded, weight: .bold)
    static let bodyFont = Font.system(.body, design: .rounded)
    static let captionFont = Font.system(.footnote, design: .rounded)
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.bodyFont.weight(.semibold))
            .foregroundColor(.white)
            .padding()
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .background(Theme.accent)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
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
