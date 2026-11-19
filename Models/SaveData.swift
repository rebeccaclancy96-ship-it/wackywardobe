import Foundation

struct SaveData: Codable {
    var coins: Int = 50
    var kidType: KidType?
    var playerName: String = ""
    var costume: String = "dino"
    var pet: String?
    var petName: String = ""
    var petOutfit: String = "plain"
    var scene: SceneStyle = .rainbow
    var ownedCostumes: Set<String> = ["dino"]
    var ownedPets: Set<String> = []
    var ownedPetOutfits: Set<String> = ["plain"]
    var ownedScenes: Set<String> = [SceneStyle.rainbow.rawValue]
    var lastSpin: Date?
    var bestStarCatch: Int = 0
    var bestMatchMoves: Int?
    // Optional so saves from before the coin shop decode without losing progress.
    var creditedCoinTransactions: Set<String>?
    var care: CareProgress?
    var dailyRewards: DailyRewardProgress?
}
