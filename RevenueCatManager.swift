import Foundation
import Observation
import RevenueCat

@MainActor
@Observable
final class RevenueCatManager {
    static let shared = RevenueCatManager()

    enum Store: String {
        case automatic, testStore, appStore
    }

    enum ConfigurationError: LocalizedError {
        case testStoreOnDevice, missingKey(String), alreadyConfigured

        var errorDescription: String? {
            switch self {
            case .testStoreOnDevice:
                return "Test Store is only enabled in the simulator. Device installs use Apple's sandbox or App Store."
            case .missingKey(let prefix):
                return "RevenueCat requires a valid \(prefix) public SDK key. Run RevenueCat setup."
            case .alreadyConfigured:
                return "RevenueCat is already configured. Change the store before startup, then relaunch."
            }
        }
    }

    private(set) var customerInfo: CustomerInfo?
    private(set) var isConfigured = false
    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    var hasAnyActiveEntitlement: Bool {
        !(customerInfo?.entitlements.active.isEmpty ?? true)
    }

    func hasEntitlement(_ identifier: String) -> Bool {
        customerInfo?.entitlements.active[identifier] != nil
    }

    // Apple selects sandbox vs production from the signed build, not the SDK key or DEBUG flag.
    static func apiKey(store: Store = .automatic, testKey: String, appleKey: String) throws -> String {
        #if targetEnvironment(simulator)
        let key = store == .appStore ? appleKey : testKey
        let prefix = store == .appStore ? "appl_" : "test_"
        #else
        guard store != .testStore else { throw ConfigurationError.testStoreOnDevice }
        let key = appleKey
        let prefix = "appl_"
        #endif
        guard key.hasPrefix(prefix), key.count > prefix.count else {
            throw ConfigurationError.missingKey(prefix)
        }
        return key
    }

    func configure(store: Store = .automatic, appUserID: String? = nil) throws {
        guard !isConfigured, !Purchases.isConfigured else { throw ConfigurationError.alreadyConfigured }
        let configuredStore = AppConfig.string("IOS_VIBECODE_REVENUECAT_STORE")
        let selectedStore = store == .automatic ? (Store(rawValue: configuredStore ?? "") ?? .automatic) : store
        let key = try Self.apiKey(
            store: selectedStore,
            testKey: AppConfig.string("IOS_VIBECODE_REVENUECAT_TEST_KEY") ?? "",
            appleKey: AppConfig.string("IOS_VIBECODE_REVENUECAT_APPLE_KEY") ?? ""
        )
        #if DEBUG
        // RevenueCat logs to the unified system log by default; print them so the app log shows purchase and receipt errors.
        Purchases.logLevel = .debug
        Purchases.logHandler = { level, message in print("[RevenueCat] \(level): \(message)") }
        #endif
        Purchases.configure(withAPIKey: key, appUserID: appUserID)
        isConfigured = true
        updatesTask = Task { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                guard !Task.isCancelled else { break }
                self?.customerInfo = info
            }
        }
    }

    var customerInfoStream: AsyncStream<CustomerInfo> {
        Purchases.shared.customerInfoStream
    }

    func refreshCustomerInfo() async throws {
        customerInfo = try await Purchases.shared.customerInfo()
    }

    func offerings() async throws -> Offerings {
        try await Purchases.shared.offerings()
    }

    func purchase(package: Package) async throws -> PurchaseResultData {
        let result = try await Purchases.shared.purchase(package: package)
        customerInfo = result.customerInfo
        return result // Includes userCancelled; callers must not treat cancellation as success.
    }

    @discardableResult
    func restorePurchases() async throws -> CustomerInfo {
        let info = try await Purchases.shared.restorePurchases()
        customerInfo = info
        return info
    }

    deinit {
        updatesTask?.cancel()
    }
}
