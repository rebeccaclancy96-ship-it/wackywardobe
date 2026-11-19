import Foundation
import Observation

enum PurchaseResult {
    case bought
    case needMore(Int)
}

/// The whole game's saved state: coins, what you own and what you're wearing.
@Observable
final class GameStore {
    private static let key = "wacky.wardrobe.save.v1"
    static let spinCooldown: TimeInterval = 60 * 60 * 3

    private(set) var save: SaveData {
        didSet { persist() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(SaveData.self, from: data) {
            save = decoded
            print("[GameStore] loaded save: coins=\(decoded.coins) kid=\(decoded.kidType?.rawValue ?? "none")")
        } else {
            save = SaveData()
            print("[GameStore] fresh save")
        }
        #if DEBUG
        DailyRewardProgress.verifyRules()
        #endif
        // Grant the new free everyday look without replacing any existing progress.
        save.ownedCostumes.insert("casual")
        persist()
    }

    // MARK: - Reads
    var coins: Int { save.coins }
    var isSetUp: Bool { save.kidType != nil && save.pet != nil }
    var kidType: KidType { save.kidType ?? .kid }
    var costume: Costume { Catalog.costume(save.costume) }
    var pet: Pet? { save.pet.map(Catalog.pet) }
    var petOutfit: String { save.petOutfit }
    var scene: SceneStyle { save.scene }
    var playerName: String { save.playerName }
    var petName: String { save.petName }

    var kidImage: String { costume.imageName(for: kidType) }
    var petImage: String? { pet?.imageName(outfit: save.petOutfit) }

    func owns(costume id: String) -> Bool { save.ownedCostumes.contains(id) }
    func owns(pet id: String) -> Bool { save.ownedPets.contains(id) }
    func owns(petOutfit id: String) -> Bool { save.ownedPetOutfits.contains(id) }
    func owns(scene: SceneStyle) -> Bool { save.ownedScenes.contains(scene.rawValue) }

    var nextSpinDate: Date? {
        guard let last = save.lastSpin else { return nil }
        let next = last.addingTimeInterval(Self.spinCooldown)
        return next > .now ? next : nil
    }

    // MARK: - Setup
    func chooseKid(_ type: KidType, name: String) {
        save.kidType = type
        save.playerName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        print("[GameStore] chose kid \(type.rawValue)")
    }

    func adoptFirstPet(_ id: String, name: String) {
        save.ownedPets.insert(id)
        save.pet = id
        save.petName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        print("[GameStore] adopted first pet \(id)")
    }

    func changeKid(_ type: KidType) { save.kidType = type }
    func rename(player: String, pet: String) {
        save.playerName = player.trimmingCharacters(in: .whitespacesAndNewlines)
        save.petName = pet.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Wear
    func wear(costume id: String) { if owns(costume: id) { save.costume = id } }
    func walk(pet id: String) {
        if owns(pet: id) {
            save.pet = id
            print("[GameStore] selected pet \(id), outfit=\(save.petOutfit)")
        }
    }
    func dressPet(_ id: String) { if owns(petOutfit: id) { save.petOutfit = id } }
    func go(to scene: SceneStyle) { if owns(scene: scene) { save.scene = scene } }

    // MARK: - Coins
    func earn(_ amount: Int, from source: String) {
        guard amount > 0 else { return }
        save.coins += amount
        print("[GameStore] +\(amount) coins from \(source) → \(save.coins)")
    }

    /// Balance and transaction ID are persisted together so a receipt can never pay twice.
    func creditPurchase(_ amount: Int, transactionID: String) {
        guard amount > 0, !transactionID.isEmpty,
              !(save.creditedCoinTransactions ?? []).contains(transactionID) else { return }
        var updated = save
        updated.coins += amount
        var credited = updated.creditedCoinTransactions ?? []
        credited.insert(transactionID)
        updated.creditedCoinTransactions = credited
        save = updated
        print("[GameStore] credited purchase \(transactionID): +\(amount) → \(save.coins)")
    }

    private func spend(_ price: Int) -> PurchaseResult {
        guard save.coins >= price else { return .needMore(price - save.coins) }
        save.coins -= price
        return .bought
    }

    func buy(costume item: Costume) -> PurchaseResult {
        // Special editions are earned through visits, never bought as zero-price catalog items.
        guard !item.isShiny else { return .needMore(0) }
        let result = spend(item.price)
        if case .bought = result { save.ownedCostumes.insert(item.id); save.costume = item.id }
        print("[GameStore] buy costume \(item.id): \(result)")
        return result
    }

    func buy(pet item: Pet) -> PurchaseResult {
        let result = spend(item.price)
        if case .bought = result { save.ownedPets.insert(item.id); save.pet = item.id }
        print("[GameStore] buy pet \(item.id): \(result), balance=\(save.coins)")
        return result
    }

    func buy(petOutfit item: PetOutfit) -> PurchaseResult {
        let result = spend(item.price)
        if case .bought = result { save.ownedPetOutfits.insert(item.id); save.petOutfit = item.id }
        return result
    }

    func buy(scene item: SceneStyle) -> PurchaseResult {
        let result = spend(item.price)
        if case .bought = result { save.ownedScenes.insert(item.rawValue); save.scene = item }
        return result
    }

    // MARK: - Buddy time
    var careProgress: CareProgress { save.care ?? CareProgress() }

    func care(_ action: CareAction, forPet: Bool) {
        var progress = careProgress
        switch (action, forPet) {
        case (.snack, false): progress.kidSnacks += 1
        case (.snack, true): progress.petSnacks += 1
        case (.drink, false): progress.kidDrinks += 1
        case (.drink, true): progress.petDrinks += 1
        case (.brush, false): progress.hairBrushed += 1
        case (.brush, true): progress.furBrushed += 1
        case (.wash, false): progress.kidWashes += 1
        case (.wash, true): progress.petWashes += 1
        }
        save.care = progress
        print("[BuddyTime] \(action.rawValue) pet=\(forPet) total=\(progress.total)")
    }

    func matchingPrice(_ look: MatchingLook) -> Int {
        let kidPrice = owns(costume: look.costume) ? 0 : Catalog.costume(look.costume).price
        let petPrice = owns(petOutfit: look.petOutfit) ? 0 : (Catalog.petOutfits.first { $0.id == look.petOutfit }?.price ?? 0)
        return kidPrice + petPrice
    }

    func wearMatching(_ look: MatchingLook) -> PurchaseResult {
        let price = matchingPrice(look)
        guard save.coins >= price else { return .needMore(price - save.coins) }
        var updated = save
        updated.coins -= price
        updated.ownedCostumes.insert(look.costume)
        updated.ownedPetOutfits.insert(look.petOutfit)
        updated.costume = look.costume
        updated.petOutfit = look.petOutfit
        save = updated
        print("[Matching] \(look.id) price=\(price) balance=\(save.coins)")
        return .bought
    }

    // MARK: - Daily rewards
    var dailyRewards: DailyRewardProgress { save.dailyRewards ?? DailyRewardProgress() }

    @discardableResult
    func claimDailyReward(at date: Date = .now) -> String? {
        var progress = dailyRewards
        guard let reward = progress.claim(at: date) else {
            print("[DailyRewards] already claimed; no credit")
            return nil
        }
        var updated = save
        updated.coins += reward.coins
        updated.dailyRewards = progress
        var message = "+\(reward.coins) coins! See you another day."
        if let edition = reward.edition {
            if updated.ownedCostumes.contains(edition) {
                updated.coins += 50
                message = "+\(reward.coins + 50) coins! Extra coins for an edition you already own."
            } else {
                updated.ownedCostumes.insert(edition)
                message = "+\(reward.coins) coins and \(Catalog.costume(edition).name)! Yours to keep."
            }
        }
        save = updated
        print("[DailyRewards] visit=\(progress.visits) coins=\(save.coins) edition=\(reward.edition ?? "none")")
        return message
    }

    // MARK: - Games
    func recordSpin() { save.lastSpin = .now }
    func recordStarCatch(score: Int) { save.bestStarCatch = max(save.bestStarCatch, score) }
    func recordMatch(moves: Int) { save.bestMatchMoves = min(save.bestMatchMoves ?? .max, moves) }
    var bestStarCatch: Int { save.bestStarCatch }
    var bestMatchMoves: Int? { save.bestMatchMoves }

    private func persist() {
        guard let data = try? JSONEncoder().encode(save) else {
            print("[GameStore] failed to encode save")
            return
        }
        UserDefaults.standard.set(data, forKey: Self.key)
    }
}
