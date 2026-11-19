import SwiftUI

struct MatchGameView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var model = MatchGameViewModel()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        ZStack {
            SceneBackground(scene: .candy)
            VStack(spacing: 14) {
                HStack {
                    Text("Moves: \(model.moves)")
                        .font(.wacky(22))
                        .foregroundStyle(Palette.ink)
                        .contentTransition(.numericText(value: Double(model.moves)))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.85), in: Capsule())
                    Spacer()
                    Text("Find the pairs!")
                        .font(.wacky(18))
                        .foregroundStyle(.white)
                        .shadow(color: Palette.ink.opacity(0.4), radius: 0, y: 2)
                }
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(model.cards) { card in
                        MatchCardView(card: card)
                            .onTapGesture { model.flip(card) }
                            .accessibilityIdentifier("match-card")
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .animation(.snappy, value: model.moves)
            if model.isDone {
                RewardCard(
                    title: "You did it!",
                    detail: "All pairs found in \(model.moves) moves",
                    coins: model.reward,
                    onAgain: { model.newGame() },
                    onDone: { dismiss() }
                )
            }
        }
        .navigationTitle("Pet Match")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: model.isDone) { _, done in
            if done {
                store.earn(model.reward, from: "match")
                store.recordMatch(moves: model.moves)
            }
        }
    }
}

private struct MatchCardView: View {
    let card: MatchGameViewModel.Card

    var body: some View {
        ZStack {
            back.opacity(card.faceUp || card.matched ? 0 : 1)
            front
                .opacity(card.faceUp || card.matched ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (0, 1, 0))
        }
        .aspectRatio(0.78, contentMode: .fit)
        .rotation3DEffect(.degrees(card.faceUp || card.matched ? 180 : 0), axis: (0, 1, 0), perspective: 0.5)
        .scaleEffect(card.matched ? 0.94 : 1)
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: card.faceUp)
        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: card.matched)
    }

    private var back: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Palette.sky.gradient)
            .overlay {
                Image(systemName: "questionmark")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white, lineWidth: 4))
            .shadow(color: Palette.skyDeep.opacity(0.5), radius: 0, y: 5)
    }

    private var front: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(.white)
            .overlay { Image(card.image).resizable().scaledToFit().padding(8) }
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(card.matched ? Palette.dino : Palette.sun, lineWidth: 4)
            )
            .shadow(color: .black.opacity(0.15), radius: 0, y: 5)
    }
}
