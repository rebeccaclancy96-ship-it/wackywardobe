import SwiftUI
import RevenueCat

/// Every new visit starts at the parent gate; approval never persists between visits.
struct CoinShopView: View {
    let store: GameStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var approved = false
    @State private var answer = ""
    @State private var gateError = false
    @State private var first = Int.random(in: 13...29)
    @State private var second = Int.random(in: 12...24)
    @State private var model = CoinShopModel.shared
    @State private var selected: Package?
    @FocusState private var answerFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    if approved { shop } else { parentGate }
                }
                .padding(24)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .background(Palette.cream.ignoresSafeArea())
            .foregroundStyle(Palette.ink)
            .navigationTitle(approved ? "Coin Shop" : "For Grown-ups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .disabled(model.purchasing)
                        .accessibilityIdentifier("close-coin-shop")
                }
            }
            .interactiveDismissDisabled(model.purchasing)
            .task(id: approved) {
                if approved { await model.load(store: store) }
            }
            .onChange(of: scenePhase) { _, phase in
                // Do not invalidate approval while Apple's own purchase sheet is presented.
                if phase == .background && !model.purchasing {
                    approved = false
                    answer = ""
                    first = Int.random(in: 13...29)
                    second = Int.random(in: 12...24)
                }
            }
            .confirmationDialog("Confirm coin purchase", isPresented: Binding(
                get: { selected != nil }, set: { if !$0 { selected = nil } }
            ), titleVisibility: .visible) {
                if let package = selected {
                    Button("Buy \(model.amount(package)) coins · \(package.storeProduct.localizedPriceString)") {
                        Task { await model.buy(package, store: store) }
                    }
                }
                Button("Cancel", role: .cancel) { selected = nil }
            } message: {
                Text("This is a one-time purchase using real money. Apple will ask you to confirm payment.")
            }
            .alert("Coin Shop", isPresented: Binding(
                get: { model.message != nil }, set: { if !$0 { model.message = nil } }
            )) { Button("OK") { model.message = nil } } message: { Text(model.message ?? "") }
        }
    }

    private var parentGate: some View {
        VStack(spacing: 22) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 54)).foregroundStyle(Palette.skyDeep)
                .padding(24).background(.white, in: Circle())
            Text("Please ask a grown-up")
                .font(.wacky(28, .black)).multilineTextAlignment(.center)
            Text("Buying coins is optional and costs real money. A grown-up needs to complete this step to open the shop.")
                .font(.system(.body, design: .rounded)).multilineTextAlignment(.center)
            VStack(spacing: 14) {
                Text("Grown-ups: what is \(first) + \(second)?")
                    .font(.wacky(19)).accessibilityIdentifier("parent-question")
                TextField("Answer", text: $answer)
                    .keyboardType(.numberPad)
                    .focused($answerFocused)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") { answerFocused = false }
                        }
                    }
                    .font(.wacky(24)).multilineTextAlignment(.center)
                    .padding(14).background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityIdentifier("parent-answer")
                if gateError {
                    Text("That's not quite right. Please ask a grown-up for help.")
                        .font(.callout).foregroundStyle(Palette.ink)
                }
                Button {
                    answerFocused = false
                    if Int(answer.trimmingCharacters(in: .whitespacesAndNewlines)) == first + second {
                        approved = true
                        gateError = false
                        answer = ""
                    } else {
                        gateError = true
                        answer = ""
                        first = Int.random(in: 13...29)
                        second = Int.random(in: 12...24)
                    }
                } label: { Text("Open coin shop").frame(maxWidth: .infinity) }
                .buttonStyle(ChunkyButtonStyle(face: Palette.sky, base: Palette.skyDeep))
                .accessibilityIdentifier("parent-continue")
            }
            Text("No purchase needed to play. Win free coins in the mini-games!")
                .font(.system(.callout, design: .rounded)).multilineTextAlignment(.center)
        }
    }

    private var shop: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("A little top-up") .font(.wacky(28, .black))
                    Text("More outfits. More wacky!").font(.system(.callout, design: .rounded))
                }
                Spacer()
                CoinIcon(size: 48)
            }
            HStack { Text("Your coins").font(.wacky(17)); Spacer(); CoinBadge(coins: store.coins) }
                .padding(16).background(.white, in: RoundedRectangle(cornerRadius: 22))
            Text("Optional, one-time purchases. No subscriptions. Prices below are real money.")
                .font(.system(.callout, design: .rounded)).multilineTextAlignment(.center)
            if model.loading { ProgressView("Loading coin packs…").padding(24) }
            if let error = model.loadError {
                Text(error).multilineTextAlignment(.center)
                Button("Try again") { Task { await model.load(store: store) } }
                    .buttonStyle(.borderedProminent).accessibilityIdentifier("coin-shop-retry")
            }
            ForEach(model.packages, id: \.identifier) { package in
                Button { selected = package } label: {
                    HStack(spacing: 14) {
                        CoinIcon(size: 42)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(model.amount(package).formatted()) coins").font(.wacky(23))
                            Text("One-time top-up").font(.system(.caption, design: .rounded))
                        }
                        Spacer(minLength: 4)
                        Text(package.storeProduct.localizedPriceString)
                            .font(.wacky(19)).foregroundStyle(.white)
                            .padding(12).background(Palette.skyDeep, in: Capsule())
                    }
                    .padding(18).background(.white, in: RoundedRectangle(cornerRadius: 24))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Palette.sun, lineWidth: 2))
                }
                .buttonStyle(SquishButtonStyle())
                .disabled(model.purchasing)
                .accessibilityIdentifier("coin-pack-\(model.amount(package))")
            }
            if model.purchasing { ProgressView("Waiting for Apple…") }
            Text("Coins don't expire. Your balance and outfits are saved on this device. Spent coins can't be restored; deleting the app can lose game progress. These packs do not renew.")
                .font(.system(.footnote, design: .rounded)).foregroundStyle(.secondary)
            Button("Back to dress-up") { dismiss() }
                .font(.wacky(17)).padding(10).disabled(model.purchasing)
                .accessibilityIdentifier("coin-shop-back")
        }
    }
}
