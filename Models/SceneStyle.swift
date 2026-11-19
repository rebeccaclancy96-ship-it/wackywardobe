import SwiftUI

enum SceneStyle: String, CaseIterable, Codable, Identifiable {
    case rainbow, ocean, jungle, space, candy
    var id: String { rawValue }

    var name: String {
        switch self {
        case .rainbow: "Rainbow"
        case .ocean: "Under the Sea"
        case .jungle: "Dino Jungle"
        case .space: "Outer Space"
        case .candy: "Candy Land"
        }
    }

    var price: Int {
        switch self {
        case .rainbow: 0
        case .ocean: 40
        case .jungle: 50
        case .space: 60
        case .candy: 80
        }
    }

    var sky: [Color] {
        switch self {
        case .rainbow: [Color(red: 0.42, green: 0.78, blue: 1.0), Color(red: 0.75, green: 0.90, blue: 1.0)]
        case .ocean: [Color(red: 0.05, green: 0.42, blue: 0.75), Color(red: 0.20, green: 0.78, blue: 0.86)]
        case .jungle: [Color(red: 0.55, green: 0.88, blue: 0.60), Color(red: 0.95, green: 0.95, blue: 0.62)]
        case .space: [Color(red: 0.06, green: 0.05, blue: 0.22), Color(red: 0.20, green: 0.15, blue: 0.45)]
        case .candy: [Color(red: 1.0, green: 0.72, blue: 0.85), Color(red: 1.0, green: 0.90, blue: 0.75)]
        }
    }

    var ground: Color {
        switch self {
        case .rainbow: Color(red: 0.45, green: 0.85, blue: 0.35)
        case .ocean: Color(red: 0.98, green: 0.86, blue: 0.58)
        case .jungle: Color(red: 0.25, green: 0.62, blue: 0.22)
        case .space: Color(red: 0.62, green: 0.62, blue: 0.70)
        case .candy: Color(red: 1.0, green: 0.55, blue: 0.70)
        }
    }

    /// Decorations scattered in the sky: (symbol, color).
    var decor: [(String, Color)] {
        switch self {
        case .rainbow: [("cloud.fill", .white), ("sparkle", .white), ("sun.max.fill", Palette.sun)]
        case .ocean: [("fish.fill", Palette.tangerine), ("bubble.fill", .white.opacity(0.7)), ("fish.fill", Palette.sun)]
        case .jungle: [("leaf.fill", Palette.dinoDeep), ("camera.macro", Palette.bubblegum), ("leaf.fill", Palette.dino)]
        case .space: [("moon.stars.fill", Palette.sun), ("sparkle", .white), ("star.fill", .white)]
        case .candy: [("heart.fill", .white), ("birthday.cake.fill", Palette.bubblegum), ("star.fill", Palette.sun)]
        }
    }
}
