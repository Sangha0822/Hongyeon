//
//  CornerThread.swift
//  Hongyeon
//

import SwiftUI

// A red thread that loops into a small bow and trails off, from the design's 393 x 90 corner decoration.
struct CornerThread: Shape {
    func path(in rect: CGRect) -> Path {
        // Maps a point from the 393 x 90 artwork onto the space SwiftUI gives the shape.
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width / 393,
                    y: rect.minY + y * rect.height / 90)
        }

        var path = Path()
        path.move(to: p(-10, 67))
        path.addCurve(to: p(146, 51), control1: p(51, 14), control2: p(88, 79))
        path.addCurve(to: p(196, 25), control1: p(169, 40), control2: p(183, 27))
        path.addCurve(to: p(208, -1), control1: p(221, 21), control2: p(225, -5))
        path.addCurve(to: p(196, 25), control1: p(199, 1), control2: p(196, 13))
        path.addCurve(to: p(178, 4), control1: p(194, 12), control2: p(186, 1))
        path.addCurve(to: p(196, 25), control1: p(160, 12), control2: p(184, 31))
        path.addCurve(to: p(339, 29), control1: p(248, 0), control2: p(287, 61))
        path.addCurve(to: p(404, 20), control1: p(361, 16), control2: p(377, 16))
        return path
    }
}

// The faint thread trailing off an onboarding screen's bottom-right corner, behind everything.
// It ignores the keyboard, so it stays put (hidden) instead of riding up while typing.
struct CornerThreadDecoration: View {
    var body: some View {
        CornerThread()
            .stroke(Theme.accent, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            .aspectRatio(393 / 90, contentMode: .fit)
            .frame(width: 200)
            .opacity(0.33)
            .offset(x: 80)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

#Preview {
    CornerThread()
        .stroke(Theme.accent, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        .aspectRatio(393 / 90, contentMode: .fit)
        .padding()
        .background(Theme.background)
}
