import SwiftUI

struct SettingsSheet: View {
    let store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var petName = ""
    @State private var showCoinShop = false
    @State private var showAppReview = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Who are you?") {
                    HStack(spacing: 10) {
                        ForEach(KidType.allCases) { type in
                            PickerChip(title: type.label, image: store.costume.imageName(for: type), isSelected: store.kidType == type) {
                                Haptics.tap()
                                store.changeKid(type)
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }
                Section("Names") {
                    TextField("Your name", text: $name)
                    TextField("Pet's name", text: $petName)
                }
                Section("Grown-ups") {
                    Button { showCoinShop = true } label: {
                        Label("Coin Shop · Optional purchases", systemImage: "lock.shield.fill")
                    }
                    .accessibilityIdentifier("settings-coin-shop")
                }
                Section {
                    Button { showAppReview = true } label: {
                        Label("Rate the App · Grown-ups", systemImage: "star.bubble")
                    }
                    .accessibilityIdentifier("settings-rate-app")
                } footer: {
                    Text("Enjoying Wacky Wardrobe? Grown-ups can share an honest review. It's always optional.")
                }
                Section("About") {
                    Link(destination: URL(string: "https://staticfiles.net/wfT_0q2yUVaf2jFDgqweP87TWmI04hkyUR5JdD4sSDw/p/n/privacy.html")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    .accessibilityIdentifier("settings-privacy-policy")
                }
                Section("Scores") {
                    LabeledContent("Best Star Catch", value: "\(store.bestStarCatch) stars")
                    LabeledContent("Best Match Game", value: store.bestMatchMoves.map { "\($0) moves" } ?? "Not played yet")
                }
            }
            .font(.system(.body, design: .rounded))
            .navigationTitle("My Stuff")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        store.rename(player: String(name.prefix(14)), pet: String(petName.prefix(14)))
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .sheet(isPresented: $showCoinShop) { CoinShopView(store: store) }
            .sheet(isPresented: $showAppReview) { RateAppSheet() }
            .onAppear {
                name = store.playerName
                petName = store.petName
            }
        }
    }
}
