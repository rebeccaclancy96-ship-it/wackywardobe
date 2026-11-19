import Foundation
import Observation

@Observable
final class MatchGameViewModel {
    struct Card: Identifiable {
        let id = UUID()
        let image: String
        var faceUp = false
        var matched = false
    }

    var cards: [Card] = []
    var moves = 0
    var isDone = false
    var reward = 0
    private var busy = false

    init() { newGame() }

    func newGame() {
        // Six pet pairs include the special friends without making the board larger.
        let faces = Catalog.pets.map { $0.imageName(outfit: "plain") }
        cards = (faces + faces).shuffled().map { Card(image: $0) }
        moves = 0
        isDone = false
        reward = 0
        busy = false
        print("[Match] new game with \(cards.count) cards")
    }

    func flip(_ card: Card) {
        guard !busy, !isDone, let index = cards.firstIndex(where: { $0.id == card.id }),
              !cards[index].faceUp, !cards[index].matched else { return }
        Haptics.tap()
        cards[index].faceUp = true
        let open = cards.indices.filter { cards[$0].faceUp && !cards[$0].matched }
        guard open.count == 2 else { return }
        moves += 1
        let first = open[0], second = open[1]
        if cards[first].image == cards[second].image {
            cards[first].matched = true
            cards[second].matched = true
            Haptics.success()
            if cards.allSatisfy(\.matched) { finish() }
        } else {
            busy = true
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(850))
                guard let self else { return }
                self.cards[first].faceUp = false
                self.cards[second].faceUp = false
                self.busy = false
            }
        }
    }

    private func finish() {
        reward = moves <= 9 ? 30 : (moves <= 13 ? 20 : 12)
        print("[Match] finished in \(moves) moves, reward \(reward)")
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(600))
            self?.isDone = true
        }
    }
}
