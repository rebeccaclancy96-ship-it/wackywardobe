import SwiftUI

struct MatchingLooksView: View {
    let store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var pending: MatchingLook?
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Better together!").font(.wacky(28, .black))
                            Text("Little looks. Big buddy energy.").font(.system(.callout, design: .rounded))
                        }
                        Spacer()
                        Image(systemName: "heart.fill").font(.largeTitle).foregroundStyle(Palette.bubblegum)
                    }
                    CoinBadge(coins: store.coins)
                    Text("Only pay coins for pieces you don't already own. Both outfits are yours to keep.")
                        .font(.system(.footnote, design: .rounded)).multilineTextAlignment(.center)
                    ForEach(MatchingLook.all) { look in
                        lookCard(look)
                    }
                }
                .padding(20).frame(maxWidth: 560).frame(maxWidth: .infinity)
            }
            .background(Palette.cream.ignoresSafeArea())
            .foregroundStyle(Palette.ink)
            .navigationTitle("Matching Looks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .alert("Get this matching look?", isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } })) {
                if let look = pending {
                    Button("Get both · \(store.matchingPrice(look)) coins") { apply(look) }
                }
                Button("Cancel", role: .cancel) { pending = nil }
            } message: {
                Text("This uses game coins, not real money. Already-owned pieces are free.")
            }
            .alert("Buddy style", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK") { message = nil }
            } message: { Text(message ?? "") }
        }
    }

    private func lookCard(_ look: MatchingLook) -> some View {
        let price = store.matchingPrice(look)
        let worn = store.save.costume == look.costume && store.petOutfit == look.petOutfit
        return VStack(spacing: 12) {
            HStack(alignment: .bottom, spacing: 0) {
                Image(Catalog.costume(look.costume).imageName(for: store.kidType))
                    .resizable().scaledToFit().frame(maxWidth: .infinity)
                if let pet = store.pet {
                    Image(pet.imageName(outfit: look.petOutfit))
                        .resizable().scaledToFit().frame(maxWidth: .infinity).padding(.vertical, 16)
                }
            }
            .frame(height: 205)
            .background((look.id == "rainbow" ? Palette.sky : Palette.bubblegum).opacity(0.10), in: RoundedRectangle(cornerRadius: 22))
            Text(look.name).font(.wacky(23))
            Text(look.detail).font(.system(.callout, design: .rounded))
            Button {
                if price == 0 { apply(look) } else { pending = look }
            } label: {
                Label(worn ? "Wearing together!" : (price == 0 ? "Wear together" : "Get both · \(price) coins"), systemImage: worn ? "checkmark.circle.fill" : "heart.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(face: Palette.dino, base: Palette.dinoDeep))
            .disabled(worn)
            .accessibilityIdentifier("match-look-\(look.id)")
        }
        .padding(16).background(.white, in: RoundedRectangle(cornerRadius: 30))
    }

    private func apply(_ look: MatchingLook) {
        switch store.wearMatching(look) {
        case .bought: Haptics.success()
        case .needMore(let amount): message = "You need \(amount) more coins. You can win them for free in the mini-games!"
        }
        pending = nil
    }
}
