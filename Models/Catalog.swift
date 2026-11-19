import SwiftUI

enum KidType: String, CaseIterable, Codable, Identifiable {
    case boy, girl, kid
    var id: String { rawValue }
    var label: String {
        switch self {
        case .boy: "Boy"
        case .girl: "Girl"
        case .kid: "Just Me"
        }
    }
}

enum WardrobeCategory: String, CaseIterable, Identifiable {
    case outfits, pets, petClothes, places
    var id: String { rawValue }
    var title: String {
        switch self {
        case .outfits: "Outfits"
        case .pets: "Pets"
        case .petClothes: "Pet Outfits"
        case .places: "Places"
        }
    }
    var symbol: String {
        switch self {
        case .outfits: "tshirt.fill"
        case .pets: "pawprint.fill"
        case .petClothes: "crown.fill"
        case .places: "mountain.2.fill"
        }
    }
    var tint: Color {
        switch self {
        case .outfits: Palette.dino
        case .pets: Palette.tangerine
        case .petClothes: Palette.bubblegum
        case .places: Palette.sky
        }
    }
}

struct Costume: Identifiable, Hashable {
    let id: String
    let name: String
    let price: Int
    var isShiny: Bool { id.hasPrefix("shiny_") }
    var baseID: String { isShiny ? String(id.dropFirst(6)) : id }
    func imageName(for kid: KidType) -> String { "kid_\(kid.rawValue)_\(baseID)" }
}

struct Pet: Identifiable, Hashable {
    let id: String
    let name: String
    let price: Int
    var isSpecialEdition: Bool { id == "unicorn" || id == "turtle" }
    var editionDescription: String {
        id == "unicorn" ? "A rainbow-maned magical friend with a golden horn." : "A little mint-green explorer with a jewel-coloured shell."
    }
    func imageName(outfit: String) -> String { "pet_\(id)_\(outfit)" }
}

struct PetOutfit: Identifiable, Hashable {
    let id: String
    let name: String
    let price: Int
}

enum Catalog {
    static let costumes: [Costume] = [
        Costume(id: "dino", name: "Dino", price: 0),
        Costume(id: "casual", name: "Everyday Tee", price: 0),
        Costume(id: "overalls", name: "Sunny Overalls", price: 35),
        Costume(id: "pajamas", name: "Starry PJs", price: 45),
        Costume(id: "rainbow", name: "Rainbow Day", price: 55),
        Costume(id: "shark", name: "Shark", price: 40),
        Costume(id: "banana", name: "Banana", price: 50),
        Costume(id: "unicorn", name: "Unicorn", price: 60),
        Costume(id: "taco", name: "Taco", price: 70),
        Costume(id: "chicken", name: "Chicken", price: 80),
        Costume(id: "pickle", name: "Pickle", price: 90),
        Costume(id: "astronaut", name: "Astronaut", price: 120),
        Costume(id: "shiny_dino", name: "Golden Dino", price: 0),
        Costume(id: "shiny_unicorn", name: "Prism Unicorn", price: 0),
        Costume(id: "shiny_astronaut", name: "Starlight Explorer", price: 0)
    ]
    static let pets: [Pet] = [
        Pet(id: "puppy", name: "Puppy", price: 60),
        Pet(id: "kitty", name: "Kitty", price: 60),
        Pet(id: "bunny", name: "Bunny", price: 60),
        Pet(id: "piggy", name: "Piggy", price: 60),
        Pet(id: "unicorn", name: "Rainbow Unicorn", price: 120),
        Pet(id: "turtle", name: "Jewel Turtle", price: 100)
    ]
    static let petOutfits: [PetOutfit] = [
        PetOutfit(id: "plain", name: "Nothing", price: 0),
        PetOutfit(id: "pajamas", name: "Starry PJs", price: 25),
        PetOutfit(id: "rainbow", name: "Rainbow Day", price: 30),
        PetOutfit(id: "strawberry", name: "Berry Hat", price: 30),
        PetOutfit(id: "bee", name: "Bumblebee", price: 40),
        PetOutfit(id: "dino", name: "Mini Dino", price: 50),
        PetOutfit(id: "hero", name: "Super Cape", price: 60)
    ]
    static let scenes: [SceneStyle] = SceneStyle.allCases

    static func costume(_ id: String) -> Costume { costumes.first { $0.id == id } ?? costumes[0] }
    static func pet(_ id: String) -> Pet { pets.first { $0.id == id } ?? pets[0] }
}
