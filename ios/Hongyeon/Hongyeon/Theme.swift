//
//  Theme.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 9/19/26.
//

import SwiftUI

enum Theme {
    static let accent = Color(red: 0.91, green: 0.33, blue: 0.35)
    static let background = Color(red: 1.0, green: 0.97, blue: 0.96)
    static let textPrimary = Color(red: 0.18, green: 0.14, blue: 0.13)

    static let titleFont = Font.system(size: 28, weight: .bold, design: .rounded)
    static let bodyFont = Font.system(size: 16, weight: .regular, design: .rounded)
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.bodyFont.weight(.semibold))
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Theme.accent)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
