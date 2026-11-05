//
//  LooseThread.swift
//  Hongyeon
//

import SwiftUI

// The part of the design's 360 x 190 artwork the threads actually use, so the
// shapes have no empty space above or below the curves.
private let artBox = CGRect(x: -4, y: 74, width: 368, height: 56)

enum ThreadSide { case left, right }

// One half of the loose red thread, painted like a brush stroke: it swells in the
// middle and tapers to a fine point at both ends.
//
// SwiftUI can't vary a line's width along its length, so instead of stroking a line
// this builds a filled outline: it samples points along the curve and pushes each one
// sideways by a width that grows toward the middle and shrinks at the ends.
struct BrushThreadHalf: Shape {
    let side: ThreadSide
    var drawn: CGFloat   // 0...1, how much of the stroke is painted so far
    var reach: CGFloat   // 0 = resting, 1 = loose end leaning toward the other half

    private static let maxWidth: CGFloat = 6   // thickest point, in artwork units
    private static let steps = 80

    // Lets SwiftUI animate both values smoothly, redrawing the shape at every step in between.
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(drawn, reach) }
        set {
            drawn = newValue.first
            reach = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        guard drawn > 0 else { return Path() }

        // Two Bézier curves per half, from the outer edge to the loose end (artwork units).
        let curves: [[CGPoint]]
        switch side {
        case .left:
            curves = [
                [CGPoint(x: -4, y: 114), CGPoint(x: 36, y: 78), CGPoint(x: 57, y: 81), CGPoint(x: 91, y: 101)],
                [CGPoint(x: 91, y: 101), CGPoint(x: 117, y: 118), CGPoint(x: 132 + 6 * reach, y: 109), CGPoint(x: 148 + 12 * reach, y: 98)],
            ]
        case .right:
            curves = [
                [CGPoint(x: 364, y: 114), CGPoint(x: 329, y: 81), CGPoint(x: 306, y: 78), CGPoint(x: 270, y: 102)],
                [CGPoint(x: 270, y: 102), CGPoint(x: 239, y: 126), CGPoint(x: 234 - 6 * reach, y: 112), CGPoint(x: 212 - 12 * reach, y: 98)],
            ]
        }

        // Sample the curve from the outer edge up to how far it's been drawn.
        var points: [CGPoint] = []
        var widths: [CGFloat] = []
        for i in 0...Self.steps {
            let t = CGFloat(i) / CGFloat(Self.steps) * drawn
            let curve = t < 0.5 ? curves[0] : curves[1]
            let local = t < 0.5 ? t * 2 : (t - 0.5) * 2
            points.append(cubicPoint(curve, local))
            // Thin at both ends, thickest in the middle.
            widths.append(Self.maxWidth * pow(sin(.pi * t), 0.6) + 0.4)
        }

        // Push each point sideways (along the curve's normal) by half its width.
        var sideA: [CGPoint] = []
        var sideB: [CGPoint] = []
        for i in points.indices {
            let before = points[max(0, i - 1)]
            let after = points[min(points.count - 1, i + 1)]
            var dx = after.x - before.x
            var dy = after.y - before.y
            let length = max(hypot(dx, dy), 0.0001)
            dx /= length
            dy /= length
            let half = widths[i] / 2
            sideA.append(CGPoint(x: points[i].x - dy * half, y: points[i].y + dx * half))
            sideB.append(CGPoint(x: points[i].x + dy * half, y: points[i].y - dx * half))
        }

        // Trace along one side and back along the other, then convert to screen space.
        let outline = sideA + sideB.reversed()
        var path = Path()
        path.addLines(outline.map { toScreen($0, in: rect) })
        path.closeSubpath()
        return path
    }

    private func cubicPoint(_ c: [CGPoint], _ t: CGFloat) -> CGPoint {
        let u = 1 - t
        let a = u * u * u, b = 3 * u * u * t, d = 3 * u * t * t, e = t * t * t
        return CGPoint(x: a * c[0].x + b * c[1].x + d * c[2].x + e * c[3].x,
                       y: a * c[0].y + b * c[1].y + d * c[2].y + e * c[3].y)
    }

    // Maps a point from the artwork onto the space SwiftUI gives the shape.
    private func toScreen(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + (point.x - artBox.minX) * rect.width / artBox.width,
                y: rect.minY + (point.y - artBox.minY) * rect.height / artBox.height)
    }
}

// Two loose ends of the red thread: they paint themselves in, then gently lean toward each other.
struct LooseThreadArt: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawn: CGFloat = 0
    @State private var reach: CGFloat = 0

    var body: some View {
        ZStack {
            ForEach([ThreadSide.left, .right], id: \.self) { side in
                BrushThreadHalf(side: side, drawn: drawn, reach: reach)
                    .fill(Theme.accent)
            }
        }
        .aspectRatio(artBox.width / artBox.height, contentMode: .fit)
        .accessibilityHidden(true)
        .onAppear {
            if reduceMotion {
                drawn = 1
                return
            }
            withAnimation(.easeOut(duration: 1.2)) {
                drawn = 1
            }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true).delay(1.2)) {
                reach = 1
            }
        }
    }
}

#Preview {
    LooseThreadArt()
        .frame(width: 260)
        .padding()
        .background(Theme.background)
}
