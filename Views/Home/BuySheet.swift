import SwiftUI

struct BuySheet: View {
    let item: WardrobeItem
    let model: HomeViewModel
    let store: GameStore
    let onPlayGames: () -> Void

    @State private var shake = false
    @State private var showCoinShop = false

    private var shortBy: Int { max(0, item.price - store.coins) }

    var body: some View {
        VStack(spacing: 16) {
            ItemPreview(item: item, store: store)
                .frame(height: 190)
                .padding(.top, 28)
                .offset(x: shake ? -10 : 0)
            Text(item.name)
                .font(.wacky(30, .black))
                .foregroundStyle(Palette.ink)
            if case .pet(let pet) = item, pet.isSpecialEdition {
                Text("✨ Special edition · Yours to keep")
                    .font(.wacky(14)).foregroundStyle(Palette.skyDeep)
                Text(pet.editionDescription + " All pet outfits fit!")
                    .font(.wacky(13)).multilineTextAlignment(.center).foregroundStyle(Palette.ink)
            }
            if shortBy == 0 {
                Button {
                    _ = model.buy(item, store: store)
                } label: {
                    HStack(spacing: 10) {
                        Text("Get it for")
                        CoinIcon(size: 26)
                        Text("\(item.price)")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(face: Palette.dino, base: Palette.dinoDeep))
                .accessibilityIdentifier("buy-confirm")
            } else {
                HStack(spacing: 6) {
                    Text("You need")
                    CoinIcon(size: 22)
                    Text("\(shortBy) more!")
                }
                .font(.wacky(20))
                .foregroundStyle(Palette.bubblegum)
                Button(action: onPlayGames) {
                    Label("Play games to win coins", systemImage: "gamecontroller.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(face: Palette.tangerine, base: Color(red: 0.78, green: 0.32, blue: 0.08)))
                .accessibilityIdentifier("buy-play-games")
                Button { showCoinShop = true } label: {
                    Label("Coin shop · Grown-ups only", systemImage: "lock.fill")
                        .font(.wacky(15)).frame(minHeight: 44)
                }
                .accessibilityIdentifier("buy-top-up")
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(Palette.cream)
        .sheet(isPresented: $showCoinShop) { CoinShopView(store: store) }
        .onAppear {
            guard shortBy > 0 else { return }
            Haptics.nope()
            withAnimation(.spring(response: 0.12, dampingFraction: 0.2).repeatCount(3, autoreverses: true)) { shake = true }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(400))
                withAnimation { shake = false }
            }
        }
    }
}
