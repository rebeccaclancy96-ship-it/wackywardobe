import SwiftUI
import Observation

@Observable
final class LuckySpinViewModel {
    static let prizes = [5, 10, 20, 5, 15, 50, 10, 25]
    static let colors: [Color] = [Palette.rainbow[0], Palette.rainbow[1], Palette.rainbow[2], Palette.rainbow[3],
                                  Palette.rainbow[4], Palette.bubblegum, Palette.tangerine, Palette.sky]

    var rotation: Double = 0
    var spinning = false
    var wonPrize: Int?

    var sliceAngle: Double { 360 / Double(Self.prizes.count) }

    /// Spins the wheel and calls `onLand` with the prize once it stops.
    func spin(onLand: @escaping (Int) -> Void) {
        guard !spinning else { return }
        spinning = true
        let index = Int.random(in: 0..<Self.prizes.count)
        let prize = Self.prizes[index]
        // Slice i is centred at i*slice + slice/2 clockwise from the top; bring it under the top pointer.
        let target = 360 - (Double(index) * sliceAngle + sliceAngle / 2)
        let current = rotation.truncatingRemainder(dividingBy: 360)
        var delta = target - current
        if delta < 0 { delta += 360 }
        print("[Spin] landing on slice \(index) prize \(prize)")
        Haptics.bump()
        withAnimation(.timingCurve(0.15, 0.6, 0.2, 1, duration: 4)) {
            rotation += 360 * 6 + delta
        }
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(4.1))
            guard let self else { return }
            self.spinning = false
            self.wonPrize = prize
            onLand(prize)
        }
    }
}
