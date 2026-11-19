import SwiftUI

enum MiniGame: String, CaseIterable, Identifiable, Hashable {
    case starCatch, gems, alphabet, numbers, match, spin
    var id: String { rawValue }
    var title: String {
        switch self {
        case .starCatch: "Star Catch"
        case .gems: "Gem Garden"
        case .alphabet: "Alphabet Adventure"
        case .numbers: "Number Buddies"
        case .match: "Pet Match"
        case .spin: "Lucky Spin"
        }
    }
    var blurb: String {
        switch self {
        case .starCatch: "Tap the falling stars!"
        case .gems: "Swap gems & win up to 60 coins"
        case .alphabet: "Play with letters · Earn 20 coins"
        case .numbers: "Count cute pets · Earn 20 coins"
        case .match: "Find the matching pairs"
        case .spin: "Spin for a free prize"
        }
    }
    var symbol: String {
        switch self {
        case .starCatch: "star.fill"
        case .gems: "diamond.fill"
        case .alphabet: "textformat.abc"
        case .numbers: "number"
        case .match: "square.grid.3x3.fill"
        case .spin: "circle.hexagongrid.fill"
        }
    }
    var colors: (Color, Color) {
        switch self {
        case .starCatch: (Palette.sky, Palette.skyDeep)
        case .gems: (Color(red: 0.60, green: 0.37, blue: 0.90), Color(red: 0.38, green: 0.20, blue: 0.65))
        case .match: (Palette.bubblegum, Color(red: 0.78, green: 0.18, blue: 0.42))
        case .spin: (Palette.dino, Palette.dinoDeep)
        case .alphabet: (Palette.bubblegum, Color(red: 0.75, green: 0.20, blue: 0.40))
        case .numbers: (Palette.sky, Palette.skyDeep)
        }
    }
}

struct GamesHubView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var path: [MiniGame] = []

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                SceneBackground(scene: .rainbow)
                ScrollView {
                    VStack(spacing: 18) {
                        Image(store.kidImage)
                            .resizable()
                            .scaledToFit()
                            .modifier(ShinyOutfitFinish(edition: store.costume.isShiny ? store.costume.id : nil))
                            .frame(height: 170)
                            .padding(.top, 4)
                        ForEach(MiniGame.allCases) { game in
                            GameCard(game: game, subtitle: subtitle(for: game)) {
                                Haptics.bump()
                                path.append(game)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Game Time!")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Close games")
                        .accessibilityIdentifier("close-games")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    CoinBadge(coins: store.coins).scaleEffect(0.85)
                }
                .sharedBackgroundVisibility(.hidden)
            }
            .navigationDestination(for: MiniGame.self) { game in
                switch game {
                case .starCatch: StarCatchView()
                case .gems: GemGardenView()
                case .alphabet: LearningGameView(kind: .alphabet)
                case .numbers: NumberBuddiesView()
                case .match: MatchGameView()
                case .spin: LuckySpinView()
                }
            }
        }
    }

    private func subtitle(for game: MiniGame) -> String {
        switch game {
        case .starCatch: store.bestStarCatch > 0 ? "Best: \(store.bestStarCatch) coins" : game.blurb
        case .gems, .alphabet, .numbers: game.blurb
        case .match: store.bestMatchMoves.map { "Best: \($0) moves" } ?? game.blurb
        case .spin: store.nextSpinDate == nil ? "Ready to spin!" : "Charging up…"
        }
    }
}

private struct GameCard: View {
    let game: MiniGame
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: game.symbol)
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.title).font(.wacky(26, .black))
                    Text(subtitle).font(.wacky(15, .semibold)).opacity(0.9)
                }
                .foregroundStyle(.white)
                Spacer()
                Image(systemName: "play.fill")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(game.colors.1)
                    .frame(width: 46, height: 46)
                    .background(.white, in: Circle())
            }
            .padding(16)
            .background(game.colors.0.gradient, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .background(game.colors.1, in: RoundedRectangle(cornerRadius: 28, style: .continuous).offset(y: 6))
        }
        .buttonStyle(SquishButtonStyle())
        .accessibilityIdentifier("game-\(game.rawValue)")
    }
}
