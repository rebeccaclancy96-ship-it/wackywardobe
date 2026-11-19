import SwiftUI

/// A native pearlescent finish over the existing costume art, plus animated star glints.
struct ShinyOutfitFinish: ViewModifier {
    let edition: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glow = false

    private var tint: Color {
        switch edition {
        case "shiny_dino": Palette.sun
        case "shiny_unicorn": Palette.bubblegum
        default: Palette.sky
        }
    }

    func body(content: Content) -> some View {
        if edition != nil {
            content
                .overlay {
                    LinearGradient(colors: [tint.opacity(0.05), tint.opacity(0.65), .white.opacity(glow ? 0.65 : 0.25), tint.opacity(0.5)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .blendMode(.plusLighter)
                        .mask(content)
                        // Keep the face and hair unchanged.
                        .mask(LinearGradient(stops: [.init(color: .clear, location: 0.25), .init(color: .white, location: 0.46)],
                                             startPoint: .top, endPoint: .bottom))
                        .allowsHitTesting(false)
                }
                .overlay {
                    GeometryReader { geo in
                        ForEach(0..<5) { index in
                            Image(systemName: "sparkle")
                                .font(.system(size: max(10, geo.size.height * 0.065), weight: .bold))
                                .foregroundStyle(index.isMultiple(of: 2) ? .white : tint)
                                .shadow(color: tint, radius: 4)
                                .scaleEffect(glow ? 1.15 : 0.75)
                                .position(x: geo.size.width * [0.30, 0.67, 0.38, 0.62, 0.48][index],
                                          y: geo.size.height * [0.48, 0.56, 0.72, 0.82, 0.92][index])
                        }
                    }.allowsHitTesting(false).accessibilityHidden(true)
                }
                .onAppear {
                    guard !reduceMotion else { return }
                    withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) { glow = true }
                }
        } else {
            content
        }
    }
}
