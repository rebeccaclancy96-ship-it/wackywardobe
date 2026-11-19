import SwiftUI

/// The dressed-up kid with their pet buddy, standing on the scene.
struct StageView: View {
    let kidImage: String
    let petImage: String?
    var compact = false
    var shinyEdition: String?

    @State private var bounce = false
    @State private var petHop = false
    @State private var breathe = false

    var body: some View {
        GeometryReader { geo in
            let kidHeight = geo.size.height * 0.98
            ZStack(alignment: .bottom) {
                Ellipse()
                    .fill(.black.opacity(0.12))
                    .frame(width: kidHeight * 0.42, height: 18)
                    .offset(x: -geo.size.width * 0.08, y: 4)
                Image(kidImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: kidHeight)
                    .modifier(ShinyOutfitFinish(edition: shinyEdition))
                    .scaleEffect(x: 1, y: breathe ? 1.015 : 1, anchor: .bottom)
                    .scaleEffect(bounce ? 1.08 : 1, anchor: .bottom)
                    .rotationEffect(.degrees(bounce ? -3 : 0), anchor: .bottom)
                    .offset(x: petImage == nil ? 0 : -geo.size.width * 0.08)
                    .id(kidImage)
                    .transition(.asymmetric(insertion: .scale(scale: 0.6).combined(with: .opacity), removal: .opacity))
                    .onTapGesture { wiggle() }
                    .accessibilityLabel("Your character")
                    .accessibilityIdentifier("stage-kid")
                if let petImage {
                    Image(petImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: kidHeight * 0.36)
                        .offset(x: geo.size.width * 0.27, y: petHop ? -24 : 0)
                        .id(petImage)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                        .onTapGesture { hop() }
                        .accessibilityLabel("Your pet")
                        .accessibilityIdentifier("stage-pet")
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.6), value: kidImage)
        .animation(.spring(response: 0.45, dampingFraction: 0.6), value: petImage)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { breathe = true }
        }
    }

    private func wiggle() {
        Haptics.bump()
        withAnimation(.spring(response: 0.2, dampingFraction: 0.35)) { bounce = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))
            withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) { bounce = false }
        }
    }

    private func hop() {
        Haptics.tap()
        withAnimation(.spring(response: 0.22, dampingFraction: 0.5)) { petHop = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.spring(response: 0.3, dampingFraction: 0.45)) { petHop = false }
        }
    }
}
