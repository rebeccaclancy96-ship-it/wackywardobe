import SwiftUI

struct HomeView: View {
    @Environment(GameStore.self) private var store
    @State private var model = HomeViewModel()
    @State private var showCoinShop = false
    @State private var showBuddyTime = false
    @State private var showMatching = false
    @State private var showDailyRewards = false

    private func isSpecialPet(_ item: WardrobeItem) -> Bool {
        if case .pet(let pet) = item { return pet.isSpecialEdition }
        return false
    }

    var body: some View {
        ZStack {
            SceneBackground(scene: store.scene)
                .animation(.easeInOut(duration: 0.5), value: store.scene)
            VStack(spacing: 10) {
                HomeTopBar(store: store, onSettings: { model.showSettings = true }, onCoins: { showCoinShop = true })
                StageView(kidImage: store.kidImage, petImage: store.petImage, shinyEdition: store.costume.isShiny ? store.costume.id : nil)
                    .padding(.horizontal, 24)
                    .frame(maxHeight: .infinity)
                Button {
                    Haptics.bump()
                    model.showGames = true
                } label: {
                    Label("Play & Win Coins", systemImage: "gamecontroller.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(face: Palette.tangerine, base: Color(red: 0.78, green: 0.32, blue: 0.08)))
                .padding(.horizontal, 20)
                .accessibilityIdentifier("play-games")
                HStack(spacing: 10) {
                    Button { showBuddyTime = true } label: {
                        Label("Buddy Time", systemImage: "heart.fill")
                            .frame(maxWidth: .infinity).frame(minHeight: 46)
                    }
                    .accessibilityIdentifier("open-buddy-time")
                    Button { showMatching = true } label: {
                        Label("Match Us!", systemImage: "tshirt.fill")
                            .frame(maxWidth: .infinity).frame(minHeight: 46)
                    }
                    .accessibilityIdentifier("open-matching-looks")
                }
                .font(.wacky(16)).foregroundStyle(Palette.ink)
                .buttonStyle(.bordered).tint(.white)
                .padding(.horizontal, 20)
                Button { showDailyRewards = true } label: {
                    Label("Daily gifts · Coins & shiny outfits", systemImage: "gift.fill")
                        .font(.wacky(15)).frame(maxWidth: .infinity).frame(minHeight: 44)
                        .background(.regularMaterial, in: Capsule())
                }
                .buttonStyle(SquishButtonStyle()).foregroundStyle(Palette.ink)
                .padding(.horizontal, 20).accessibilityIdentifier("open-daily-rewards")
                WardrobePanel(model: model, store: store)
            }
            if model.celebrate { ConfettiView() }
        }
        .sheet(item: $model.pendingItem) { item in
            BuySheet(item: item, model: model, store: store, onPlayGames: {
                model.pendingItem = nil
                model.showGames = true
            })
            .presentationDetents([.height(isSpecialPet(item) ? 600 : 520)])
            .presentationCornerRadius(36)
        }
        .sheet(isPresented: $showDailyRewards) { DailyRewardsView(store: store) }
        .fullScreenCover(isPresented: $showBuddyTime) { BuddyTimeView(store: store) }
        .sheet(isPresented: $showMatching) { MatchingLooksView(store: store) }
        .sheet(isPresented: $showCoinShop) { CoinShopView(store: store) }
        .sheet(isPresented: $model.showSettings) {
            SettingsSheet(store: store)
                .presentationDetents([.medium, .large])
        }
        .fullScreenCover(isPresented: $model.showGames) {
            GamesHubView()
        }
    }
}

private struct HomeTopBar: View {
    let store: GameStore
    let onSettings: () -> Void
    let onCoins: () -> Void

    private var title: String {
        let me = store.playerName.isEmpty ? "Me" : store.playerName
        let buddy = store.petName.isEmpty ? (store.pet?.name ?? "") : store.petName
        return buddy.isEmpty ? me : "\(me) & \(buddy)"
    }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onSettings) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Palette.skyDeep)
                    .frame(width: 44, height: 44)
                    .background(.regularMaterial, in: Circle())
            }
            .buttonStyle(SquishButtonStyle())
            .accessibilityLabel("Settings")
            .accessibilityIdentifier("settings-button")
            Text(title)
                .font(.wacky(20, .black))
                .foregroundStyle(.white)
                .shadow(color: Palette.ink.opacity(0.5), radius: 0, x: 0, y: 2)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer(minLength: 8)
            Button(action: onCoins) {
                HStack(spacing: 4) {
                    CoinBadge(coins: store.coins)
                    Image(systemName: "plus.circle.fill").foregroundStyle(Palette.skyDeep)
                }
                .frame(minHeight: 44)
            }
            .buttonStyle(SquishButtonStyle())
            .accessibilityLabel("\(store.coins) coins. Coin shop, grown-ups only")
            .accessibilityIdentifier("open-coin-shop")
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }
}
