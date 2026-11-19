import SwiftUI

/// A playful, fully drawn backdrop for the stage.
struct SceneBackground: View {
    let scene: SceneStyle
    @State private var drift = false

    private let spots: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (0.12, 0.10, 34), (0.86, 0.08, 46), (0.70, 0.24, 26), (0.20, 0.32, 40),
        (0.92, 0.40, 30), (0.06, 0.52, 24), (0.50, 0.06, 22), (0.40, 0.20, 18)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: scene.sky, startPoint: .top, endPoint: .bottom)
                if scene == .rainbow { rainbow(in: geo.size) }
                if scene == .space { starfield(in: geo.size) }
                ForEach(Array(spots.enumerated()), id: \.offset) { index, spot in
                    let item = scene.decor[index % scene.decor.count]
                    Image(systemName: item.0)
                        .font(.system(size: spot.size))
                        .foregroundStyle(item.1)
                        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                        .position(x: geo.size.width * spot.x, y: geo.size.height * spot.y)
                        .offset(y: drift ? (index.isMultiple(of: 2) ? -8 : 8) : 0)
                }
                ground(in: geo.size)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) { drift = true }
        }
    }

    private func rainbow(in size: CGSize) -> some View {
        ZStack {
            ForEach(Array(Palette.rainbow.enumerated()), id: \.offset) { index, color in
                Circle()
                    .stroke(color.opacity(0.85), lineWidth: 18)
                    .frame(width: size.width * 1.3 - CGFloat(index) * 36)
            }
        }
        .position(x: size.width / 2, y: size.height * 0.62)
    }

    private func starfield(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            var rng = SeededRandom(seed: 7)
            for _ in 0..<70 {
                let point = CGPoint(x: rng.next() * canvasSize.width, y: rng.next() * canvasSize.height * 0.75)
                let radius = 0.8 + rng.next() * 1.8
                context.fill(Path(ellipseIn: CGRect(x: point.x, y: point.y, width: radius, height: radius)), with: .color(.white.opacity(0.8)))
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func ground(in size: CGSize) -> some View {
        ZStack {
            Ellipse()
                .fill(scene.ground.opacity(0.7))
                .frame(width: size.width * 1.6, height: size.height * 0.5)
                .offset(x: -size.width * 0.3)
            Ellipse()
                .fill(scene.ground)
                .frame(width: size.width * 1.8, height: size.height * 0.46)
                .offset(x: size.width * 0.25, y: size.height * 0.04)
        }
        .position(x: size.width / 2, y: size.height * 0.98)
    }
}

struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat((state >> 33) % 10_000) / 10_000
    }
}
