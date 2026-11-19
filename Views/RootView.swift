import SwiftUI

struct RootView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ZStack {
            if store.isSetUp {
                HomeView().transition(.opacity)
            } else {
                OnboardingView().transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: store.isSetUp)
    }
}
