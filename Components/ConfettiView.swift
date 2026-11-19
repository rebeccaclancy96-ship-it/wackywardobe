import SwiftUI

/// Bursting confetti for celebrations.
struct ConfettiView: View {
    private struct Piece: Identifiable {
        let id = UUID()
        let x: CGFloat
        let delay: Double
        let speed: CGFloat
        let spin: Double
        let color: Color
        let size: CGFloat
        let sway: CGFloat
    }

    @State private var start = Date()
    private let pieces: [Piece] = (0..<90).map { _ in
        Piece(x: .random(in: 0...1), delay: .random(in: 0...0.8), speed: .random(in: 220...420),
              spin: .random(in: 90...400), color: Palette.rainbow.randomElement() ?? .yellow,
              size: .random(in: 8...14), sway: .random(in: 10...40))
    }

    var body: some View {
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSince(start)
            Canvas { gc, size in
                for piece in pieces {
                    let t = elapsed - piece.delay
                    guard t > 0 else { continue }
                    let y = -20 + CGFloat(t) * piece.speed
                    guard y < size.height + 20 else { continue }
                    let x = piece.x * size.width + sin(CGFloat(t) * 3) * piece.sway
                    var inner = gc
                    inner.translateBy(x: x, y: y)
                    inner.rotate(by: .degrees(piece.spin * t))
                    let rect = CGRect(x: -piece.size / 2, y: -piece.size / 4, width: piece.size, height: piece.size / 2)
                    inner.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(piece.color))
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
