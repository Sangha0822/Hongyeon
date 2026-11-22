//
//  PairingThread.swift
//  Hongyeon
//

import SwiftUI

// The design's pairing animation: two thread ends meet in the middle, then the join opens into a heart.
// Ported from the Figma prototype's 360 x 190 artwork; only the band from y 40 to 140 is drawn.
// The first 55% of progress brings the ends together, the remaining 45% forms the heart.
private let approachShare: CGFloat = 0.55

private func lerp(_ from: CGFloat, _ to: CGFloat, _ t: CGFloat) -> CGFloat {
    from + (to - from) * t
}

private func ease(_ t: CGFloat) -> CGFloat {
    t * t * (3 - 2 * t)
}

private func point(in rect: CGRect, _ x: CGFloat, _ y: CGFloat) -> CGPoint {
    CGPoint(x: rect.minX + x * rect.width / 360,
            y: rect.minY + (y - 40) * rect.height / 100)
}

struct PairingThread: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { point(in: rect, x, y) }

        let approach = ease(min(1, progress / approachShare))
        let heart = ease(max(0, (progress - approachShare) / (1 - approachShare)))
        let endY = lerp(98, 100, approach)
        let joinY = lerp(100, 112, heart)
        // Heart points grow out of the meeting point as the heart forms.
        func h(_ x: CGFloat, _ y: CGFloat) -> CGPoint { p(lerp(180, x, heart), lerp(100, y, heart)) }

        var path = Path()
        path.move(to: p(-4, 114))
        path.addCurve(to: p(91, 101), control1: p(36, 78), control2: p(57, 81))

        if progress < approachShare {
            path.addCurve(to: p(lerp(148, 180, approach), endY),
                          control1: p(117, 118),
                          control2: p(lerp(132, 144, approach), lerp(109, 100, approach)))

            path.move(to: p(lerp(212, 180, approach), endY))
            path.addCurve(to: p(270, 102),
                          control1: p(lerp(234, 218, approach), lerp(112, 102, approach)),
                          control2: p(239, 126))
        } else {
            path.addCurve(to: p(180, joinY), control1: p(117, 118), control2: p(144, 100))
            path.addCurve(to: h(163, 57), control1: h(156, 94), control2: h(142, 54))
            path.addCurve(to: h(181, 78), control1: h(173, 58), control2: h(179, 70))
            path.addCurve(to: h(217, 68), control1: h(188, 57), control2: h(211, 51))
            path.addCurve(to: p(180, joinY), control1: h(228, 95), control2: h(199, 109))
            path.addCurve(to: p(270, 102), control1: p(218, lerp(102, 92, heart)), control2: p(239, 126))
        }

        path.addCurve(to: p(364, 114), control1: p(306, 78), control2: p(329, 81))
        return path
    }
}

// The dots at the two loose tips; they shrink away as the ends meet.
struct PairingThreadTips: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let approach = ease(min(1, progress / approachShare))
        let radius = 2.6 * rect.width / 360 * max(0, 1 - progress / approachShare)
        let endY = lerp(98, 100, approach)

        var path = Path()
        for x in [lerp(148, 180, approach), lerp(212, 180, approach)] {
            let center = point(in: rect, x, endY)
            path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius,
                                       width: radius * 2, height: radius * 2))
        }
        return path
    }
}

struct PairingThreadArt: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0
    @State private var knotted = false

    var body: some View {
        ZStack {
            PairingThread(progress: progress)
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
            PairingThreadTips(progress: progress)
                .fill(Theme.accent)
        }
        .aspectRatio(360 / 100, contentMode: .fit)
        .accessibilityHidden(true)
        .sensoryFeedback(.impact(weight: .light), trigger: knotted)
        .onAppear {
            if reduceMotion {
                progress = 1
                return
            }
            // Linear on purpose: ease() inside the shapes already shapes each phase.
            withAnimation(.linear(duration: 1).delay(0.3)) {
                progress = 1
            }
            Task {
                try? await Task.sleep(for: .seconds(1.3))
                knotted = true
            }
        }
    }
}

#Preview {
    PairingThreadArt()
        .padding(.vertical)
        .background(Theme.background)
}
