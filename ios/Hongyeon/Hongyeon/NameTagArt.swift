//
//  NameTagArt.swift
//  Hongyeon
//

import SwiftUI

// A paper name tag tied to the red thread, from the design's 360 x 190 "name" illustration.
// It says "hello, you" until the user types a name, then greets them by it.
struct NameTagArt: View {
    let name: String

    var body: some View {
        Canvas { context, size in
            // Draw in the artwork's own 360 x 190 coordinates and let the context scale them to fit.
            // Only the band from y 32 to 162 is shown: the rest is empty, and cropping it
            // lets the tag grow without the art taking more height.
            context.scaleBy(x: size.width / 360, y: size.height / 130)
            context.translateBy(x: 0, y: -32)

            let threadStyle = StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round)

            let thread = Path { path in
                path.move(to: CGPoint(x: -5, y: 103))
                path.addCurve(to: CGPoint(x: 76, y: 65), control1: CGPoint(x: 32, y: 101), control2: CGPoint(x: 43, y: 54))
                path.addCurve(to: CGPoint(x: 80, y: 112), control1: CGPoint(x: 97, y: 72), control2: CGPoint(x: 98, y: 107))
                path.addCurve(to: CGPoint(x: 75, y: 95), control1: CGPoint(x: 65, y: 117), control2: CGPoint(x: 62, y: 102))
                path.addCurve(to: CGPoint(x: 189, y: 133), control1: CGPoint(x: 103, y: 80), control2: CGPoint(x: 136, y: 139))
                path.addCurve(to: CGPoint(x: 365, y: 95), control1: CGPoint(x: 257, y: 125), control2: CGPoint(x: 270, y: 75))
            }
            context.stroke(thread, with: .color(Theme.accent.opacity(0.7)), style: threadStyle)

            // The tag is tilted 7° around its center. Tilting a copy of the context
            // keeps the tilt off everything drawn outside the tag.
            var tag = context
            tag.translateBy(x: 180, y: 98)
            tag.rotate(by: .degrees(-7))
            tag.translateBy(x: -180, y: -98)

            let card = Path { path in
                path.move(to: CGPoint(x: 91, y: 62))
                path.addLine(to: CGPoint(x: 115, y: 47))
                path.addLine(to: CGPoint(x: 266, y: 52))
                path.addLine(to: CGPoint(x: 263, y: 147))
                path.addLine(to: CGPoint(x: 113, y: 145))
                path.addLine(to: CGPoint(x: 89, y: 126))
                path.closeSubpath()
            }
            // A layer, so the soft paper shadow falls only under the card, not under the writing.
            tag.drawLayer { layer in
                layer.addFilter(.shadow(color: Theme.textPrimary.opacity(0.08), radius: 2, x: 1, y: 3))
                layer.fill(card, with: .color(Theme.cardBackground))
            }
            tag.stroke(card, with: .color(Theme.line), lineWidth: 0.8)

            let innerBorder = Path { path in
                path.move(to: CGPoint(x: 120, y: 58))
                path.addLine(to: CGPoint(x: 255, y: 62))
                path.addLine(to: CGPoint(x: 252, y: 136))
                path.addLine(to: CGPoint(x: 122, y: 134))
            }
            tag.stroke(innerBorder, with: .color(Theme.line.opacity(0.7)), lineWidth: 0.6)

            let hole = Path(ellipseIn: CGRect(x: 101, y: 95, width: 8, height: 8))
            tag.fill(hole, with: .color(Theme.background))
            tag.stroke(hole, with: .color(Theme.textSecondary.opacity(0.4)), lineWidth: 0.7)

            // The thread looping through the punched hole.
            let knot = Path { path in
                path.move(to: CGPoint(x: 77, y: 95))
                path.addQuadCurve(to: CGPoint(x: 108, y: 98), control: CGPoint(x: 104, y: 86))
                path.addQuadCurve(to: CGPoint(x: 105, y: 107), control: CGPoint(x: 111, y: 107))
                path.addQuadCurve(to: CGPoint(x: 95, y: 96), control: CGPoint(x: 95, y: 103))
            }
            tag.stroke(knot, with: .color(Theme.accent), style: threadStyle)

            let greeting = name.isEmpty ? "hello, you" : "hello, \(name)"
            let handwriting = tag.resolve(
                Text(greeting)
                    .font(.custom("Caveat-Regular", fixedSize: 28))
                    .foregroundStyle(Theme.textPrimary)
            )
            // Long names shrink to fit the tag instead of running off it.
            let textWidth = handwriting.measure(in: CGSize(width: CGFloat.infinity, height: CGFloat.infinity)).width
            let shrink = min(1, 130 / textWidth)
            var writing = tag
            writing.translateBy(x: 185, y: 96)
            writing.scaleBy(x: shrink, y: shrink)
            writing.draw(handwriting, at: .zero)

            let underline = Path { path in
                path.move(to: CGPoint(x: 145, y: 116))
                path.addQuadCurve(to: CGPoint(x: 224, y: 115), control: CGPoint(x: 185, y: 121))
            }
            tag.stroke(underline, with: .color(Theme.blush.opacity(0.65)), lineWidth: 0.7)

            let petal = Path { path in
                path.move(to: CGPoint(x: 290, y: 48))
                path.addCurve(to: CGPoint(x: 291, y: 63), control1: CGPoint(x: 283, y: 49), control2: CGPoint(x: 281, y: 58))
                path.addCurve(to: CGPoint(x: 290, y: 48), control1: CGPoint(x: 300, y: 55), control2: CGPoint(x: 297, y: 48))
            }
            context.fill(petal, with: .color(Theme.blossom))

            let ticks = Path { path in
                path.move(to: CGPoint(x: 57, y: 144))
                path.addLine(to: CGPoint(x: 65, y: 142))
                path.move(to: CGPoint(x: 60, y: 149))
                path.addLine(to: CGPoint(x: 67, y: 146))
            }
            context.stroke(ticks, with: .color(Theme.textSecondary.opacity(0.4)), lineWidth: 0.6)
        }
        .aspectRatio(360 / 130, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 24) {
        NameTagArt(name: "")
        NameTagArt(name: "Sangha")
        NameTagArt(name: "A really long name for a tag")
    }
    .padding()
    .background(Theme.background)
}
