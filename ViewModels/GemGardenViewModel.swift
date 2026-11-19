import Foundation
import Observation

/// Match-three rules are independent of the UI; colours also have distinct shapes.
@MainActor
@Observable
final class GemGardenViewModel {
    static let side = 6
    static let roundMoves = 12
    struct Gem: Identifiable {
        let id = UUID()
        let kind: Int
    }
    private(set) var board: [Gem] = []
    private(set) var selected: Int?
    private(set) var hint: [Int] = []
    private(set) var clearing: Set<Int> = []
    private(set) var movesLeft = roundMoves
    private(set) var cleared = 0
    private(set) var busy = false
    private(set) var done = false
    private(set) var message = "Tap a gem, then a neighbour to swap!"
    private(set) var turn = 0
    private(set) var roundID = UUID()
    private var pendingSwap: (Int, Int)?
    private(set) var credited = false

    var reward: Int { cleared == 0 ? 0 : min(60, 5 + cleared / 3) }

    init() { newGame() }

    func newGame() {
        roundID = UUID()
        movesLeft = Self.roundMoves
        cleared = 0
        selected = nil
        hint = []
        clearing = []
        pendingSwap = nil
        busy = false
        done = false
        credited = false
        message = "Tap a gem, then a neighbour to swap!"
        freshBoard()
    }

    func select(_ index: Int) {
        guard !busy, !done, board.indices.contains(index) else { return }
        hint = []
        guard let first = selected else { selected = index; return }
        if first == index { selected = nil; return }
        guard Self.neighbours(first, index) else {
            selected = index
            message = "Choose a gem right beside this one."
            return
        }
        selected = nil
        pendingSwap = (first, index)
        busy = true
        turn += 1
    }

    func swipe(from index: Int, row: Int, column: Int) {
        guard !busy, !done else { return }
        let r = index / Self.side + row
        let c = index % Self.side + column
        guard (0..<Self.side).contains(r), (0..<Self.side).contains(c) else { return }
        selected = index
        select(r * Self.side + c)
    }

    func resolveTurn() async {
        guard let (a, b) = pendingSwap, busy else { return }
        pendingSwap = nil
        let identity = roundID
        board.swapAt(a, b)
        guard await pause(), roundID == identity else { return }
        var matches = Self.matches(board.map(\.kind))
        if matches.isEmpty {
            board.swapAt(a, b)
            message = "Try another pair—no move lost!"
            busy = false
            print("[GemGarden] invalid swap; moves=\(movesLeft)")
            return
        }
        movesLeft -= 1
        var cascade = 0
        while !matches.isEmpty && cascade < 30 {
            cascade += 1
            clearing = matches
            cleared += matches.count
            message = cascade > 1 ? "Cascade! More sparkly matches!" : "Lovely match!"
            guard await pause(), roundID == identity else { return }
            collapse(removing: matches)
            clearing = []
            guard await pause(), roundID == identity else { return }
            matches = Self.matches(board.map(\.kind))
        }
        if !matches.isEmpty || legalMove() == nil {
            freshBoard()
            message = "A fresh garden! Your score stays."
        }
        busy = false
        print("[GemGarden] cleared=\(cleared) moves=\(movesLeft) coins=\(reward) cascades=\(cascade)")
        if movesLeft == 0 { finish() }
    }

    func showHint() {
        guard !busy, !done else { return }
        selected = nil
        if let pair = legalMove() {
            hint = [pair.0, pair.1]
            message = "Swap the two glowing gems. Hints are free!"
        } else {
            freshBoard()
            message = "Fresh gems, same score. Try a hint!"
        }
    }

    func finish() {
        guard !busy, !done, cleared > 0 else { return }
        selected = nil
        hint = []
        done = true
    }

    /// Claim is idempotent even if the result view appears more than once.
    func claimReward() -> Int? {
        guard done, !credited else { return nil }
        credited = true
        return reward
    }

    private func pause() async -> Bool {
        do { try await Task.sleep(for: .milliseconds(180)); return true }
        catch { return false }
    }

    private func freshBoard() {
        // Avoid immediate matches, and regenerate until a real swap is possible.
        repeat {
            var gems: [Gem] = []
            for i in 0..<(Self.side * Self.side) {
                var choices = Array(0..<5)
                if i % Self.side >= 2, gems[i - 1].kind == gems[i - 2].kind {
                    choices.removeAll { $0 == gems[i - 1].kind }
                }
                if i >= Self.side * 2, gems[i - Self.side].kind == gems[i - Self.side * 2].kind {
                    choices.removeAll { $0 == gems[i - Self.side].kind }
                }
                gems.append(Gem(kind: choices.randomElement()!))
            }
            board = gems
        } while legalMove() == nil
    }

    private func collapse(removing matches: Set<Int>) {
        var next = board
        for column in 0..<Self.side {
            let survivors = (0..<Self.side).map { $0 * Self.side + column }
                .filter { !matches.contains($0) }.map { board[$0] }
            let incoming = (0..<(Self.side - survivors.count)).map { _ in Gem(kind: Int.random(in: 0..<5)) }
            let gems = incoming + survivors
            for row in 0..<Self.side { next[row * Self.side + column] = gems[row] }
        }
        board = next
    }

    func legalMove() -> (Int, Int)? {
        var kinds = board.map(\.kind)
        for index in kinds.indices {
            for other in [index + 1, index + Self.side] where kinds.indices.contains(other) && Self.neighbours(index, other) {
                kinds.swapAt(index, other)
                let found = !Self.matches(kinds).isEmpty
                kinds.swapAt(index, other)
                if found { return (index, other) }
            }
        }
        return nil
    }

    static func neighbours(_ a: Int, _ b: Int) -> Bool {
        abs(a / side - b / side) + abs(a % side - b % side) == 1
    }

    static func matches(_ kinds: [Int]) -> Set<Int> {
        guard kinds.count == side * side else { return [] }
        var found: Set<Int> = []
        for row in 0..<side {
            for column in 0..<side {
                let index = row * side + column
                if column + 2 < side, kinds[index] == kinds[index + 1], kinds[index] == kinds[index + 2] {
                    found.formUnion([index, index + 1, index + 2])
                }
                if row + 2 < side, kinds[index] == kinds[index + side], kinds[index] == kinds[index + side * 2] {
                    found.formUnion([index, index + side, index + side * 2])
                }
            }
        }
        return found
    }
}
