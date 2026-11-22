//
//  LocationPinsArt.swift
//  Hongyeon
//

import SwiftUI

// Two map pins tied together by the red thread, labelled "you" and the partner's name,
// after the design's location illustration. Drawn in 240 x 125 artwork coordinates.
struct LocationPinsArt: View {
    let partnerName: String

    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 240, y: size.height / 125)

            // Under the pins, so each pin's tip covers the thread's end.
            let thread = Path { path in
                path.move(to: CGPoint(x: 72, y: 72))
                path.addCurve(to: CGPoint(x: 114, y: 96), control1: CGPoint(x: 80, y: 95), control2: CGPoint(x: 100, y: 100))
                path.addCurve(to: CGPoint(x: 128, y: 76), control1: CGPoint(x: 124, y: 92), control2: CGPoint(x: 132, y: 84))
                path.addCurve(to: CGPoint(x: 117, y: 80), control1: CGPoint(x: 125, y: 70), control2: CGPoint(x: 116, y: 72))
                path.addCurve(to: CGPoint(x: 140, y: 96), control1: CGPoint(x: 118, y: 90), control2: CGPoint(x: 128, y: 98))
                path.addCurve(to: CGPoint(x: 168, y: 64), control1: CGPoint(x: 155, y: 94), control2: CGPoint(x: 166, y: 80))
            }
            context.stroke(thread, with: .color(Theme.accent.opacity(0.75)),
                           style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))

            drawPin(in: context, center: CGPoint(x: 62, y: 32), tilt: -15,
                    fill: Theme.line.opacity(0.6), stroke: Theme.textSecondary.opacity(0.35))
            drawPin(in: context, center: CGPoint(x: 178, y: 22), tilt: 15,
                    fill: Theme.blossom, stroke: Theme.blush.opacity(0.8))

            drawLabel("you", in: context, at: CGPoint(x: 58, y: 112))
            drawLabel(partnerName, in: context, at: CGPoint(x: 182, y: 100))
        }
        .aspectRatio(240 / 125, contentMode: .fit)
        .accessibilityHidden(true)
    }

    // A teardrop pin: a round head with its tip 2.2 radii below the center, tilted around the center.
    private func drawPin(in context: GraphicsContext, center c: CGPoint, tilt: Double, fill: Color, stroke: Color) {
        var pin = context
        pin.translateBy(x: c.x, y: c.y)
        pin.rotate(by: .degrees(tilt))

        let r: CGFloat = 20
        let k: CGFloat = 0.552 // control-point distance that makes cubic curves look like a circle
        let shape = Path { path in
            path.move(to: CGPoint(x: 0, y: r * 2.2))
            path.addCurve(to: CGPoint(x: -r, y: 0), control1: CGPoint(x: -r * 0.35, y: r * 1.5), control2: CGPoint(x: -r, y: r * 0.9))
            path.addCurve(to: CGPoint(x: 0, y: -r), control1: CGPoint(x: -r, y: -r * k), control2: CGPoint(x: -r * k, y: -r))
            path.addCurve(to: CGPoint(x: r, y: 0), control1: CGPoint(x: r * k, y: -r), control2: CGPoint(x: r, y: -r * k))
            path.addCurve(to: CGPoint(x: 0, y: r * 2.2), control1: CGPoint(x: r, y: r * 0.9), control2: CGPoint(x: r * 0.35, y: r * 1.5))
            path.closeSubpath()
        }
        pin.fill(shape, with: .color(fill))
        pin.stroke(shape, with: .color(stroke), lineWidth: 1)

        let ring = Path(ellipseIn: CGRect(x: -7, y: -7, width: 14, height: 14))
        pin.fill(ring, with: .color(Theme.cardBackground))
        pin.stroke(ring, with: .color(Theme.textSecondary.opacity(0.3)), lineWidth: 0.8)
        pin.fill(Path(ellipseIn: CGRect(x: -2.5, y: -2.5, width: 5, height: 5)), with: .color(Theme.accent))
    }

    // Long names shrink to fit under the pin instead of running off the art.
    private func drawLabel(_ text: String, in context: GraphicsContext, at point: CGPoint) {
        let label = context.resolve(
            Text(text)
                .font(.custom("Caveat-Regular", fixedSize: 20))
                .foregroundStyle(Theme.textPrimary)
        )
        let width = label.measure(in: CGSize(width: CGFloat.infinity, height: CGFloat.infinity)).width
        let shrink = min(1, 90 / width)
        var writing = context
        writing.translateBy(x: point.x, y: point.y)
        writing.scaleBy(x: shrink, y: shrink)
        writing.draw(label, at: .zero)
    }
}

#Preview {
    VStack(spacing: 24) {
        LocationPinsArt(partnerName: "Jamie")
        LocationPinsArt(partnerName: "A very long partner name")
    }
    .frame(width: 260)
    .padding()
    .background(Theme.background)
}
