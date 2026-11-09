//
//  ThreadHeart.swift
//  Hongyeon
//

import SwiftUI

// One red thread that loops into a heart and trails off, from the design's 64 x 34 logo mark.
struct ThreadHeart: Shape {
    func path(in rect: CGRect) -> Path {
        // Maps a point from the 64 x 34 artwork onto the space SwiftUI gives the shape.
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width / 64,
                    y: rect.minY + y * rect.height / 34)
        }

        var path = Path()
        path.move(to: p(2, 25))
        path.addCurve(to: p(29, 23), control1: p(11, 24), control2: p(19, 16))
        path.addCurve(to: p(27, 6), control1: p(18, 16), control2: p(20, 4))
        path.addCurve(to: p(35, 15), control1: p(32, 7), control2: p(35, 12))
        path.addCurve(to: p(50, 12), control1: p(39, 4), control2: p(49, 5))
        path.addCurve(to: p(29, 23), control1: p(52, 20), control2: p(40, 24))
        path.addCurve(to: p(62, 15), control1: p(40, 29), control2: p(50, 22))
        return path
    }
}

// The thread heart draws itself in from left to right, then beats slowly.
struct ThreadHeartArt: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawn: CGFloat = 0
    @State private var beat = false

    var body: some View {
        ThreadHeart()
            .trim(from: 0, to: drawn)
            .stroke(Theme.accent, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
            .aspectRatio(64 / 34, contentMode: .fit)
            .scaleEffect(beat ? 1.04 : 1)
            .accessibilityHidden(true)
            .onAppear {
                if reduceMotion {
                    drawn = 1
                    return
                }
                withAnimation(.easeInOut(duration: 1.6)) {
                    drawn = 1
                }
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(1.6)) {
                    beat = true
                }
            }
            // A covered screen stays alive in the navigation stack, and a hidden repeatForever
            // animation still runs every frame, making typing on the next screen stutter.
            // A new one-off animation replaces the repeating one; onAppear restarts it on return.
            .onDisappear {
                withAnimation(.easeOut(duration: 0.2)) {
                    beat = false
                }
            }
    }
}

#Preview {
    ThreadHeartArt()
        .frame(width: 200)
        .padding()
        .background(Theme.background)
}
