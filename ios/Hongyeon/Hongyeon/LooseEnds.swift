//
//  LooseEnds.swift
//  Hongyeon
//

import SwiftUI

// One of two thread ends reaching toward each other across a gap, from the design's
// 360 x 190 pairing illustration. Only the band from y 66 to 138 is drawn.
// Each path runs from the screen edge inward, so trimming draws it toward the middle.
struct LooseEnd: Shape {
    let isRight: Bool

    func path(in rect: CGRect) -> Path {
        // Maps a point from the 360 x 190 artwork onto the space SwiftUI gives the shape.
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width / 360,
                    y: rect.minY + (y - 66) * rect.height / 72)
        }

        var path = Path()
        if isRight {
            path.move(to: p(364, 114))
            path.addCurve(to: p(270, 102), control1: p(329, 81), control2: p(306, 78))
            path.addCurve(to: p(212, 98), control1: p(239, 126), control2: p(234, 112))
        } else {
            path.move(to: p(-4, 114))
            path.addCurve(to: p(91, 101), control1: p(36, 78), control2: p(57, 81))
            path.addCurve(to: p(148, 98), control1: p(117, 118), control2: p(132, 109))
        }
        return path
    }
}

// The small dot at the tip of a thread end.
struct LooseEndTip: Shape {
    let isRight: Bool

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.minX + (isRight ? 212 : 148) * rect.width / 360,
                             y: rect.minY + (98 - 66) * rect.height / 72)
        let radius = 2.6 * rect.width / 360
        return Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                      width: radius * 2, height: radius * 2))
    }
}

// The two ends draw themselves in from the screen edges once, then stay still.
struct LooseEndsArt: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawn: CGFloat = 0
    @State private var showsTips = false

    var body: some View {
        ZStack {
            ForEach([false, true], id: \.self) { isRight in
                LooseEnd(isRight: isRight)
                    .trim(from: 0, to: drawn)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))

                LooseEndTip(isRight: isRight)
                    .fill(Theme.accent)
                    .opacity(showsTips ? 1 : 0)
            }
        }
        .aspectRatio(360 / 72, contentMode: .fit)
        .accessibilityHidden(true)
        .onAppear {
            if reduceMotion {
                drawn = 1
                showsTips = true
                return
            }
            withAnimation(.easeInOut(duration: 1.2)) {
                drawn = 1
            }
            withAnimation(.easeOut(duration: 0.3).delay(1.0)) {
                showsTips = true
            }
        }
    }
}

#Preview {
    LooseEndsArt()
        .padding(.vertical)
        .background(Theme.background)
}
