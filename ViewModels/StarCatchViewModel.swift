import SwiftUI
import Observation

@Observable
final class StarCatchViewModel {
    enum Phase { case ready, playing, done }
    enum Kind: CaseIterable {
        case star, coin, rainbow
        var value: Int { switch self { case .star: 1; case .coin: 2; case .rainbow: 5 } }
        var size: CGFloat { switch self { case .star: 66; case .coin: 60; case .rainbow: 76 } }
    }
    struct Faller: Identifiable {
        let id = UUID()
        let kind: Kind
        let x: CGFloat
        let born: Date
        let speed: CGFloat
        let spin: Double
    }
    struct Pop: Identifiable {
        let id = UUID()
        let point: CGPoint
        let value: Int
    }

    static let duration = 30

    var phase: Phase = .ready
    var fallers: [Faller] = []
    var pops: [Pop] = []
    var score = 0
    var timeLeft = duration
    var areaHeight: CGFloat = 700
    private var loop: Task<Void, Never>?

    func start() {
        print("[StarCatch] start")
        fallers = []
        pops = []
        score = 0
        timeLeft = Self.duration
        phase = .playing
        loop?.cancel()
        loop = Task { @MainActor [weak self] in
            var ticks = 0
            while let self, self.phase == .playing, !Task.isCancelled {
                self.spawn()
                try? await Task.sleep(for: .milliseconds(400))
                ticks += 1
                if ticks % 5 == 0 {
                    self.timeLeft -= 2
                    if self.timeLeft <= 0 { self.finish() }
                }
                self.cleanup()
            }
        }
    }

    func stop() { loop?.cancel() }

    private func spawn() {
        let roll = Int.random(in: 0..<20)
        let kind: Kind = roll == 0 ? .rainbow : (roll < 6 ? .coin : .star)
        // Things fall a little faster as time runs out.
        let pace = 1 + CGFloat(Self.duration - timeLeft) / CGFloat(Self.duration) * 0.5
        fallers.append(Faller(kind: kind, x: .random(in: 0.1...0.9), born: .now,
                              speed: .random(in: 115...175) * pace, spin: .random(in: -90...90)))
    }

    private func cleanup() {
        let now = Date()
        fallers.removeAll { y(for: $0, at: now) > areaHeight + 80 }
        if pops.count > 8 { pops.removeFirst(pops.count - 8) }
    }

    func y(for faller: Faller, at date: Date) -> CGFloat {
        -50 + CGFloat(date.timeIntervalSince(faller.born)) * faller.speed
    }

    func catchFaller(_ faller: Faller, at point: CGPoint) {
        guard phase == .playing, let index = fallers.firstIndex(where: { $0.id == faller.id }) else { return }
        fallers.remove(at: index)
        score += faller.kind.value
        pops.append(Pop(point: point, value: faller.kind.value))
        faller.kind == .rainbow ? Haptics.success() : Haptics.tap()
    }

    private func finish() {
        phase = .done
        fallers = []
        print("[StarCatch] finished score=\(score)")
    }
}
