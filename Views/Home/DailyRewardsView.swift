import SwiftUI

struct DailyRewardsView: View {
    let store: GameStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var now = Date.now
    @State private var celebration: String?

    private var progress: DailyRewardProgress { store.dailyRewards }
    private var editionID: String { progress.cardEdition ?? DailyRewardProgress.featured(at: now) }
    private var edition: Costume { Catalog.costume(editionID) }
    private var ready: Bool { progress.canClaim(at: now) }
    private var resetDate: Date {
        Date(timeIntervalSince1970: Double(DailyRewardProgress.day(now) + 1) * 86_400)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(red: 0.91, green: 0.85, blue: 1), Palette.cream], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            Label("Little visits, lovely gifts", systemImage: "gift.fill").font(.wacky(18))
                            Spacer()
                            CoinBadge(coins: store.coins).scaleEffect(0.85)
                        }
                        Text("Your 7-visit gift card").font(.wacky(29, .black))
                        Text("One free gift each day you visit. Miss a day? Your progress waits for you.")
                            .font(.wacky(16)).multilineTextAlignment(.center)
                        featuredOutfit
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(0..<7) { index in
                                dayCard(index)
                            }
                        }
                        if let celebration {
                            Label(celebration, systemImage: "checkmark.seal.fill")
                                .font(.wacky(18)).multilineTextAlignment(.center).foregroundStyle(Palette.dinoDeep)
                                .accessibilityIdentifier("daily-reward-result")
                        }
                        Button {
                            now = .now
                            if let result = store.claimDailyReward(at: now) {
                                celebration = result
                                Haptics.success()
                            }
                        } label: {
                            Label(ready ? "Open today's gift · +\(DailyRewardProgress.coins[progress.nextIndex]) coins" : "Today's gift collected!",
                                  systemImage: ready ? "gift.fill" : "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(ChunkyButtonStyle(face: Palette.dino, base: Palette.dinoDeep))
                        .disabled(!ready).accessibilityIdentifier("claim-daily-reward")
                        if !ready {
                            Text("Next gift: \(resetDate.formatted(date: .abbreviated, time: .shortened))")
                                .font(.system(.footnote, design: .rounded)).accessibilityIdentifier("daily-next-gift")
                        }
                        Text("Every 7 visits: a shiny edition plus 60 coins! Already own that edition? Get 50 extra coins instead. "
                             + "Featured editions rotate monthly and may return. A card you've started keeps its outfit until you finish.")
                            .font(.system(.footnote, design: .rounded)).multilineTextAlignment(.center)
                        Text("Gifts refresh at midnight UTC (shown in your local time). No account needed. Rewards and outfits are saved on this device.")
                            .font(.system(.caption, design: .rounded)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    .padding(20).frame(maxWidth: 540).frame(maxWidth: .infinity)
                }
            }
            .foregroundStyle(Palette.ink)
            .navigationTitle("Daily Gifts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.accessibilityIdentifier("close-daily-rewards") } }
            .task {
                while !Task.isCancelled {
                    now = .now
                    do { try await Task.sleep(for: .seconds(15)) } catch { return }
                }
            }
            .onChange(of: scenePhase) { _, phase in if phase == .active { now = .now } }
        }
    }

    private var featuredOutfit: some View {
        VStack(spacing: 10) {
            HStack {
                Label("SHINY EDITION", systemImage: "sparkles").font(.wacky(12))
                Spacer()
                Text(progress.cardEdition == nil ? "This month's pick" : "Saved on your card").font(.wacky(12))
            }.foregroundStyle(Palette.skyDeep)
            Image(edition.imageName(for: store.kidType)).resizable().scaledToFit().frame(height: 170)
                .modifier(ShinyOutfitFinish(edition: editionID))
                .accessibilityLabel("Shiny \(edition.name) preview").accessibilityIdentifier("daily-edition-preview")
            Text(edition.name).font(.wacky(25, .black))
            Text("Pearlescent colour & twinkling sparkles · Visit 7 reward")
                .font(.wacky(14)).multilineTextAlignment(.center)
            if store.owns(costume: editionID) {
                Button("Wear \(edition.name)") { store.wear(costume: editionID); Haptics.bump() }
                    .buttonStyle(.borderedProminent).tint(Palette.skyDeep).accessibilityIdentifier("wear-daily-edition")
            }
        }
        .padding(18).frame(maxWidth: .infinity)
        .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 28))
    }

    private func dayCard(_ index: Int) -> some View {
        let completed = index < progress.nextIndex
        let current = index == progress.nextIndex
        return VStack(spacing: 8) {
            HStack {
                Text("Visit \(index + 1)").font(.wacky(15))
                Spacer()
                Image(systemName: completed ? "checkmark.circle.fill" : (index == 6 ? "sparkles" : "gift.fill"))
            }
            Text("+\(DailyRewardProgress.coins[index]) coins").font(.wacky(21, .black))
            if index == 6 { Text("+ Shiny outfit").font(.wacky(13)) }
            Text(completed ? "Collected" : (current ? (ready ? "Ready today!" : "Next visit") : "Keep visiting"))
                .font(.wacky(12)).foregroundStyle(.secondary)
        }
        .padding(14).frame(maxWidth: .infinity).frame(minHeight: 100)
        .background(current ? Palette.sun.opacity(0.3) : .white.opacity(0.8), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(current ? Palette.sunDeep : .clear, lineWidth: 2))
        .accessibilityElement(children: .combine).accessibilityIdentifier("daily-visit-\(index + 1)")
    }
}
