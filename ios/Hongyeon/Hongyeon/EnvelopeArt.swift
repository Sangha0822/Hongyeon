//
//  EnvelopeArt.swift
//  Hongyeon
//

import SwiftUI

// A tilted paper envelope sealed with a heart, from the design's sign-in illustration.
struct EnvelopeArt: View {
    var body: some View {
        Canvas { context, size in
            // Draw in the artwork's own 150 x 100 coordinates and let the context scale them to fit.
            context.scaleBy(x: size.width / 150, y: size.height / 100)

            // The envelope is tilted 6° around its center. Tilting a copy of the context
            // keeps the tilt off the petal drawn afterwards.
            var envelope = context
            envelope.translateBy(x: 70, y: 50)
            envelope.rotate(by: .degrees(-6))
            envelope.translateBy(x: -70, y: -50)

            let body = Path(roundedRect: CGRect(x: 24, y: 17, width: 96, height: 66), cornerRadius: 3)

            // A flat, offset shadow, like a paper cut-out lifted off the page.
            envelope.fill(body.offsetBy(dx: 3, dy: 5), with: .color(Theme.line.opacity(0.7)))
            envelope.fill(body, with: .color(Theme.cardBackground))
            envelope.stroke(body, with: .color(Theme.line), lineWidth: 1)

            let flap = Path { path in
                path.move(to: CGPoint(x: 24.5, y: 17.5))
                path.addLine(to: CGPoint(x: 72, y: 52))
                path.addLine(to: CGPoint(x: 119.5, y: 17.5))
                path.closeSubpath()
            }
            envelope.fill(flap, with: .color(Theme.background))
            envelope.stroke(flap, with: .color(Theme.line), style: StrokeStyle(lineWidth: 0.9, lineJoin: .round))

            let folds = Path { path in
                path.move(to: CGPoint(x: 24.5, y: 82.5))
                path.addLine(to: CGPoint(x: 64, y: 50))
                path.move(to: CGPoint(x: 119.5, y: 82.5))
                path.addLine(to: CGPoint(x: 80, y: 50))
            }
            envelope.stroke(folds, with: .color(Theme.line), lineWidth: 0.9)

            // The heart seal where the flap meets the folds.
            let heart = Path { path in
                path.move(to: CGPoint(x: 72, y: 61))
                path.addCurve(to: CGPoint(x: 67.5, y: 45.5), control1: CGPoint(x: 62, y: 54), control2: CGPoint(x: 62, y: 45.5))
                path.addCurve(to: CGPoint(x: 72, y: 49.5), control1: CGPoint(x: 70, y: 45.5), control2: CGPoint(x: 72, y: 48))
                path.addCurve(to: CGPoint(x: 76.5, y: 45.5), control1: CGPoint(x: 72, y: 48), control2: CGPoint(x: 74, y: 45.5))
                path.addCurve(to: CGPoint(x: 72, y: 61), control1: CGPoint(x: 82, y: 45.5), control2: CGPoint(x: 82, y: 54))
                path.closeSubpath()
            }
            envelope.fill(heart, with: .color(Theme.cardBackground))
            envelope.stroke(heart, with: .color(Theme.accent), style: StrokeStyle(lineWidth: 1.6, lineJoin: .round))

            let petal = Path { path in
                path.move(to: CGPoint(x: 136, y: 36))
                path.addCurve(to: CGPoint(x: 137, y: 49), control1: CGPoint(x: 130, y: 37), control2: CGPoint(x: 128, y: 45))
                path.addCurve(to: CGPoint(x: 136, y: 36), control1: CGPoint(x: 145, y: 42), control2: CGPoint(x: 142, y: 36))
            }
            context.fill(petal, with: .color(Theme.blossom))
        }
        .aspectRatio(150 / 100, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

#Preview {
    EnvelopeArt()
        .frame(width: 200)
        .padding()
        .background(Theme.background)
}
