import Foundation
import Observation

@Observable
final class HomeViewModel {
    var category: WardrobeCategory = .outfits
    var pendingItem: WardrobeItem?
    var showGames = false
    var showSettings = false
    var celebrate = false

    func items(in category: WardrobeCategory) -> [WardrobeItem] {
        switch category {
        case .outfits: Catalog.costumes.map(WardrobeItem.costume)
        case .pets:
            (Catalog.pets.filter(\.isSpecialEdition) + Catalog.pets.filter { !$0.isSpecialEdition }).map(WardrobeItem.pet)
        case .petClothes: Catalog.petOutfits.map(WardrobeItem.petOutfit)
        case .places: Catalog.scenes.map(WardrobeItem.scene)
        }
    }

    func isOwned(_ item: WardrobeItem, store: GameStore) -> Bool {
        switch item {
        case .costume(let c): store.owns(costume: c.id)
        case .pet(let p): store.owns(pet: p.id)
        case .petOutfit(let o): store.owns(petOutfit: o.id)
        case .scene(let s): store.owns(scene: s)
        }
    }

    func isWorn(_ item: WardrobeItem, store: GameStore) -> Bool {
        switch item {
        case .costume(let c): store.costume.id == c.id
        case .pet(let p): store.pet?.id == p.id
        case .petOutfit(let o): store.petOutfit == o.id
        case .scene(let s): store.scene == s
        }
    }

    /// Tapping an item: wear it if owned, otherwise offer to buy it.
    func tap(_ item: WardrobeItem, store: GameStore) {
        guard isOwned(item, store: store) else {
            Haptics.tap()
            pendingItem = item
            return
        }
        Haptics.bump()
        switch item {
        case .costume(let c): store.wear(costume: c.id)
        case .pet(let p): store.walk(pet: p.id)
        case .petOutfit(let o): store.dressPet(o.id)
        case .scene(let s): store.go(to: s)
        }
    }

    func buy(_ item: WardrobeItem, store: GameStore) -> PurchaseResult {
        let result: PurchaseResult
        switch item {
        case .costume(let c): result = store.buy(costume: c)
        case .pet(let p): result = store.buy(pet: p)
        case .petOutfit(let o): result = store.buy(petOutfit: o)
        case .scene(let s): result = store.buy(scene: s)
        }
        if case .bought = result {
            Haptics.success()
            pendingItem = nil
            celebrate = true
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3))
                celebrate = false
            }
        } else {
            Haptics.nope()
        }
        return result
    }
}
