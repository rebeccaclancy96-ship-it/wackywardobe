import Foundation

struct MatchingLook: Identifiable {
    let id: String
    let name: String
    let detail: String
    let costume: String
    let petOutfit: String

    static let all: [MatchingLook] = [
        .init(id: "pajamas", name: "Sleepover Stars", detail: "Cosy starry PJs for two", costume: "pajamas", petOutfit: "pajamas"),
        .init(id: "rainbow", name: "Rainbow Buddies", detail: "A colourful matching day", costume: "rainbow", petOutfit: "rainbow"),
        .init(id: "dino", name: "Dino Duo", detail: "Big roars, little paws", costume: "dino", petOutfit: "dino")
    ]
}

enum CareAction: String, CaseIterable, Identifiable {
    case snack, drink, brush, wash
    var id: String { rawValue }
    var title: String {
        switch self {
        case .snack: "Feed"
        case .drink: "Water"
        case .brush: "Brush"
        case .wash: "Wash"
        }
    }
    var symbol: String {
        switch self {
        case .snack: "carrot.fill"
        case .drink: "drop.fill"
        case .brush: "comb.fill"
        case .wash: "bubbles.and.sparkles.fill"
        }
    }
}

struct CareProgress: Codable {
    var kidSnacks = 0
    var petSnacks = 0
    var kidDrinks = 0
    var petDrinks = 0
    var hairBrushed = 0
    var furBrushed = 0
    var kidWashes = 0
    var petWashes = 0
    var total: Int { kidSnacks + petSnacks + kidDrinks + petDrinks + hairBrushed + furBrushed + kidWashes + petWashes }
}
