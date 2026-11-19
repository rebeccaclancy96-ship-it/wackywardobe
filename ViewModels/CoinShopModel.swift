import Foundation
import Observation
import RevenueCat

@MainActor
@Observable
final class CoinShopModel {
    static let shared = CoinShopModel()
    static let amounts = [
        "com.vibecodeapp.app_4thf0g3bzcmz.coins.100": 100,
        "com.vibecodeapp.app_4thf0g3bzcmz.coins.500": 500,
        "com.vibecodeapp.app_4thf0g3bzcmz.coins.1200": 1200
    ]

    private(set) var packages: [Package] = []
    private(set) var loading = false
    private(set) var purchasing = false
    var message: String?
    private(set) var loadError: String?
    @ObservationIgnored private var started = false
    @ObservationIgnored private var updates: Task<Void, Never>?

    func start(store: GameStore) {
        guard !started else { return }
        do {
            if !RevenueCatManager.shared.isConfigured {
                try RevenueCatManager.shared.configure(store: .appStore)
            }
            started = true
            print("[CoinShop] customer=\(Purchases.shared.appUserID)")
            updates = Task {
                for await info in RevenueCatManager.shared.customerInfoStream {
                    guard !Task.isCancelled else { return }
                    reconcile(info, store: store)
                }
            }
            Task {
                do {
                    try await RevenueCatManager.shared.refreshCustomerInfo()
                    if let info = RevenueCatManager.shared.customerInfo { reconcile(info, store: store) }
                } catch { print("[CoinShop] purchase recovery: \(error)") }
            }
        } catch {
            print("[CoinShop] configuration: \(error)")
            loadError = "The coin shop isn't available right now. You can still earn coins by playing."
        }
    }

    func load(store: GameStore) async {
        start(store: store)
        guard started, !loading else { return }
        loading = true
        loadError = nil
        defer { loading = false }
        do {
            let offerings = try await RevenueCatManager.shared.offerings()
            packages = (offerings.all["coin_shop"]?.availablePackages ?? [])
                .filter { Self.amounts[$0.storeProduct.productIdentifier] != nil }
                .sorted { amount($0) < amount($1) }
            if packages.isEmpty { loadError = "Coin packs aren't available yet. Please try again later, or earn coins in the games." }
            print("[CoinShop] loaded \(packages.count) packs")
        } catch {
            print("[CoinShop] offerings: \(error)")
            loadError = "We couldn't load the shop. Check your connection and try again."
        }
    }

    func amount(_ package: Package) -> Int { Self.amounts[package.storeProduct.productIdentifier] ?? 0 }

    func buy(_ package: Package, store: GameStore) async {
        guard !purchasing else { return }
        purchasing = true
        message = nil
        defer { purchasing = false }
        do {
            let result = try await RevenueCatManager.shared.purchase(package: package)
            guard !result.userCancelled else {
                print("[CoinShop] cancelled; no coins added")
                return
            }
            reconcile(result.customerInfo, store: store)
            message = "Purchase complete! Your coins have been added."
            Haptics.success()
            print("[CoinShop] completed \(package.storeProduct.productIdentifier); balance=\(store.coins)")
        } catch {
            print("[CoinShop] purchase: \(error)")
            let nsError = error as NSError
            if nsError.code == ErrorCode.paymentPendingError.rawValue {
                message = "Waiting for Apple's approval. Coins will appear after the purchase is approved."
            } else {
                message = "The purchase didn't complete. No new coins were added. Please try again."
            }
        }
    }

    private func reconcile(_ info: CustomerInfo, store: GameStore) {
        for transaction in info.nonSubscriptions {
            guard let amount = Self.amounts[transaction.productIdentifier] else { continue }
            store.creditPurchase(amount, transactionID: transaction.transactionIdentifier)
        }
    }
}
