//
//  CalendarArt.swift
//  Hongyeon
//

import SwiftUI

// A small calendar page with the red thread looped around one day,
// after the design's anniversary illustration. Drawn in 150 x 80 artwork coordinates.
struct CalendarArt: View {
    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 150, y: size.height / 80)
            context.translateBy(x: 75, y: 40)
            context.rotate(by: .degrees(-5))
            context.translateBy(x: -75, y: -40)

            let page = Path(roundedRect: CGRect(x: 52, y: 14, width: 46, height: 56), cornerRadius: 3)
            context.drawLayer { layer in
                layer.addFilter(.shadow(color: Theme.textPrimary.opacity(0.08), radius: 2, x: 1, y: 2))
                layer.fill(page, with: .color(Theme.cardBackground))
            }

            let header = Path(roundedRect: CGRect(x: 52, y: 14, width: 46, height: 11),
                              cornerRadii: RectangleCornerRadii(topLeading: 3, topTrailing: 3))
            context.fill(header, with: .color(Theme.blossom))
            context.stroke(page, with: .color(Theme.line), lineWidth: 0.8)

            let rings = Path { path in
                path.move(to: CGPoint(x: 63, y: 9))
                path.addLine(to: CGPoint(x: 63, y: 18))
                path.move(to: CGPoint(x: 87, y: 9))
                path.addLine(to: CGPoint(x: 87, y: 18))
            }
            context.stroke(rings, with: .color(Theme.textSecondary.opacity(0.6)),
                           style: StrokeStyle(lineWidth: 1, lineCap: .round))

            for row in 0..<4 {
                for column in 0..<4 {
                    let center = CGPoint(x: 60 + CGFloat(column) * 10, y: 34 + CGFloat(row) * 9)
                    let isTheDay = row == 2 && column == 2
                    let radius: CGFloat = isTheDay ? 1.4 : 1
                    let dot = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                                     width: radius * 2, height: radius * 2))
                    context.fill(dot, with: .color(isTheDay ? Theme.accent : Theme.textSecondary.opacity(0.35)))
                }
            }

            // Comes in from the left, circles the day at (80, 52), and trails off to the right.
            let thread = Path { path in
                path.move(to: CGPoint(x: -4, y: 66))
                path.addCurve(to: CGPoint(x: 70, y: 57), control1: CGPoint(x: 25, y: 72), control2: CGPoint(x: 50, y: 66))
                path.addCurve(to: CGPoint(x: 80, y: 45), control1: CGPoint(x: 66, y: 51), control2: CGPoint(x: 72, y: 45))
                path.addCurve(to: CGPoint(x: 88, y: 53), control1: CGPoint(x: 86, y: 45), control2: CGPoint(x: 89, y: 49))
                path.addCurve(to: CGPoint(x: 75, y: 59), control1: CGPoint(x: 87, y: 58), control2: CGPoint(x: 80, y: 60))
                path.addCurve(to: CGPoint(x: 154, y: 50), control1: CGPoint(x: 100, y: 60), control2: CGPoint(x: 125, y: 44))
            }
            context.stroke(thread, with: .color(Theme.accent),
                           style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
        }
        .aspectRatio(150 / 80, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

#Preview {
    CalendarArt()
        .frame(width: 180)
        .padding()
        .background(Theme.background)
}
