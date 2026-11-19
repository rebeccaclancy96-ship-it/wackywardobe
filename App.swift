import SwiftUI

@main
struct MyApp: App {
    @State private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(.light)
                .task { CoinShopModel.shared.start(store: store) }
        }
    }
}
