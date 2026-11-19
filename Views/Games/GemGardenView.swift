import SwiftUI

struct GemGardenView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var model = GemGardenViewModel()
    @State private var showFinish = false
    @Namespace private var gemSpace
    private let symbols = ["diamond.fill", "heart.fill", "star.fill", "leaf.fill", "drop.fill"]
    private let names = ["purple diamond", "pink heart", "gold star", "green leaf", "blue drop"]
    private let colors: [Color] = [Color(red: 0.57, green: 0.34, blue: 0.91), Palette.bubblegum, Palette.sunDeep, Palette.dinoDeep, Palette.sky]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.90, green: 0.85, blue: 1), Color(red: 0.94, green: 0.98, blue: 0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    HStack(spacing: 12) {
                        stat("Moves left", value: "\(model.movesLeft)", symbol: "arrow.left.arrow.right")
                        stat("Coins to win", value: "\(model.reward)", symbol: "star.circle.fill")
                    }
                    HStack(spacing: 10) {
                        Image(systemName: "leaf.fill").foregroundStyle(Palette.dinoDeep)
                        Text("A little swap. A lot of sparkle.").font(.wacky(17))
                    }
                    board
                    Text(model.message)
                        .font(.wacky(17)).multilineTextAlignment(.center)
                        .frame(minHeight: 48).accessibilityIdentifier("gem-message")
                    HStack(spacing: 12) {
                        Button { Haptics.tap(); model.showHint() } label: {
                            Label("Hint", systemImage: "lightbulb.fill").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(ChunkyButtonStyle(face: Palette.sky, base: Palette.skyDeep))
                        .disabled(model.busy || model.done).accessibilityIdentifier("gem-hint")
                        Button { showFinish = true } label: {
                            Label("Finish", systemImage: "checkmark.flag.fill").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(ChunkyButtonStyle(face: Palette.dino, base: Palette.dinoDeep))
                        .disabled(model.busy || model.cleared == 0 || model.done).accessibilityIdentifier("gem-finish")
                    }
                    Text("Match 3 or more in a row. Tap two neighbours or swipe a gem. 12 matching moves per round, no timer. Cascades earn extra coins!")
                        .font(.system(.footnote, design: .rounded)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Text("\(model.cleared) gems collected · Up to 60 coins per round")
                        .font(.wacky(14)).accessibilityIdentifier("gem-score")
                }
                .padding(18).frame(maxWidth: 520).frame(maxWidth: .infinity)
            }
            .allowsHitTesting(!model.done)
            if model.done {
                RewardCard(title: "Gem-tastic!", detail: "\(model.cleared) sparkly gems collected", coins: model.reward,
                           onAgain: { model.newGame() }, onDone: { dismiss() })
            }
        }
        .foregroundStyle(Palette.ink)
        .navigationTitle("Gem Garden")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: model.turn) { await model.resolveTurn() }
        .onChange(of: model.done) { _, done in
            if done, let coins = model.claimReward() { store.earn(coins, from: "gem-garden") }
        }
        .confirmationDialog("Finish this round?", isPresented: $showFinish, titleVisibility: .visible) {
            Button("Finish & collect \(model.reward) coins") { model.finish() }
            Button("Keep playing", role: .cancel) { }
        } message: { Text("Your matches so far count. You can start another free round afterwards.") }
    }

    private var board: some View {
        GeometryReader { geo in
            let gap: CGFloat = 5
            let size = (geo.size.width - gap * 5) / 6
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: gap), count: 6), spacing: gap) {
                ForEach(0..<model.board.count, id: \.self) { index in
                    let gem = model.board[index]
                    let active = model.selected == index || model.hint.contains(index)
                    Button { Haptics.tap(); model.select(index) } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 13).fill(.white.opacity(0.75))
                            RoundedRectangle(cornerRadius: 11).fill(colors[gem.kind].opacity(0.12)).padding(3)
                            Image(systemName: symbols[gem.kind])
                                .font(.system(size: size * 0.51, weight: .bold))
                                .foregroundStyle(colors[gem.kind].gradient)
                                .shadow(color: colors[gem.kind].opacity(0.30), radius: 0, y: 3)
                                .overlay(alignment: .topLeading) {
                                    Circle().fill(.white.opacity(0.8)).frame(width: 5, height: 5).offset(x: 3, y: 4)
                                }
                                .matchedGeometryEffect(id: gem.id, in: gemSpace)
                                .scaleEffect(model.clearing.contains(index) ? 0.1 : 1)
                                .opacity(model.clearing.contains(index) ? 0 : 1)
                            RoundedRectangle(cornerRadius: 13).stroke(active ? Palette.sun : .white.opacity(0.7), lineWidth: active ? 4 : 1)
                        }
                        .frame(height: size)
                    }
                    .buttonStyle(.plain)
                    .disabled(model.busy || model.done)
                    .highPriorityGesture(DragGesture(minimumDistance: 15).onEnded { value in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        if abs(dx) > abs(dy) { model.swipe(from: index, row: 0, column: dx > 0 ? 1 : -1) }
                        else { model.swipe(from: index, row: dy > 0 ? 1 : -1, column: 0) }
                    })
                    .accessibilityLabel("Row \(index / 6 + 1), column \(index % 6 + 1), \(names[gem.kind])\(active ? ", glowing" : "")")
                    .accessibilityIdentifier("gem-cell-\(index)")
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(10)
        .background(Color(red: 0.35, green: 0.24, blue: 0.52).opacity(0.18), in: RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(.white.opacity(0.85), lineWidth: 3))
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: model.board.map(\.id))
        .animation(.easeOut(duration: 0.16), value: model.clearing)
    }

    private func stat(_ title: String, value: String, symbol: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).font(.title2).foregroundStyle(Palette.skyDeep)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.wacky(12))
                Text(value).font(.wacky(28, .black)).monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .padding(14).background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(title == "Moves left" ? "gem-moves" : "gem-reward")
    }
}
