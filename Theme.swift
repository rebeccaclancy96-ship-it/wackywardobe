import SwiftUI
import UIKit

enum Palette {
    static let dino = Color(red: 0.30, green: 0.78, blue: 0.24)
    static let dinoDeep = Color(red: 0.13, green: 0.52, blue: 0.16)
    static let sun = Color(red: 1.00, green: 0.80, blue: 0.13)
    static let sunDeep = Color(red: 0.93, green: 0.58, blue: 0.05)
    static let sky = Color(red: 0.20, green: 0.56, blue: 0.98)
    static let skyDeep = Color(red: 0.10, green: 0.33, blue: 0.80)
    static let bubblegum = Color(red: 1.00, green: 0.38, blue: 0.62)
    static let tangerine = Color(red: 1.00, green: 0.52, blue: 0.20)
    static let ink = Color(red: 0.12, green: 0.10, blue: 0.20)
    static let cream = Color(red: 1.00, green: 0.98, blue: 0.93)
    static let rainbow: [Color] = [
        Color(red: 1.00, green: 0.33, blue: 0.36), Color(red: 1.00, green: 0.60, blue: 0.20),
        Color(red: 1.00, green: 0.86, blue: 0.24), Color(red: 0.36, green: 0.84, blue: 0.36),
        Color(red: 0.25, green: 0.66, blue: 1.00), Color(red: 0.58, green: 0.44, blue: 0.98)
    ]
}

extension Font {
    static func wacky(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func bump() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func nope() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}

/// Chunky, toy-like button: a solid face sitting on a darker "base" that squishes down when pressed.
struct ChunkyButtonStyle: ButtonStyle {
    var face: Color
    var base: Color
    var corner: CGFloat = 22

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(.wacky(20))
            .foregroundStyle(.white)
            .shadow(color: base.opacity(0.6), radius: 0, x: 0, y: 2)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(face.gradient)
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .fill(.white.opacity(0.28))
                            .frame(height: 10)
                            .padding(.horizontal, 10)
                            .padding(.top, 5)
                    }
            }
            .background {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(base)
                    .offset(y: pressed ? 1 : 6)
            }
            .offset(y: pressed ? 5 : 0)
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: pressed)
    }
}

/// A slight squish for tappable tiles.
struct SquishButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.55), value: configuration.isPressed)
    }
}
