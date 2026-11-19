import Foundation

enum WardrobeItem: Identifiable, Hashable {
    case costume(Costume)
    case pet(Pet)
    case petOutfit(PetOutfit)
    case scene(SceneStyle)

    var id: String {
        switch self {
        case .costume(let c): "costume-\(c.id)"
        case .pet(let p): "pet-\(p.id)"
        case .petOutfit(let o): "outfit-\(o.id)"
        case .scene(let s): "scene-\(s.rawValue)"
        }
    }

    var name: String {
        switch self {
        case .costume(let c): c.name
        case .pet(let p): p.name
        case .petOutfit(let o): o.name
        case .scene(let s): s.name
        }
    }

    var price: Int {
        switch self {
        case .costume(let c): c.price
        case .pet(let p): p.price
        case .petOutfit(let o): o.price
        case .scene(let s): s.price
        }
    }
}
