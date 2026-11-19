import Foundation

struct DailyRewardProgress: Codable {
    var lastClaimDay: Int?
    var visits = 0
    // Lock the edition when a seven-visit card starts, so a month change never loses a prize.
    var cardEdition: String?

    static let coins = [10, 15, 20, 25, 30, 40, 60]
    static func day(_ date: Date) -> Int { Int(floor(date.timeIntervalSince1970 / 86_400)) }
    func canClaim(at date: Date) -> Bool { lastClaimDay.map { Self.day(date) > $0 } ?? true }
    var nextIndex: Int { visits % 7 }

    static func featured(at date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = calendar.dateComponents([.year, .month], from: date)
        let month = (components.year ?? 2026) * 12 + (components.month ?? 1) - 1
        return editions[month % editions.count]
    }
    static let editions = ["shiny_dino", "shiny_unicorn", "shiny_astronaut"]

    mutating func claim(at date: Date) -> (coins: Int, edition: String?)? {
        guard canClaim(at: date) else { return nil }
        if cardEdition == nil { cardEdition = Self.featured(at: date) }
        let index = nextIndex
        let edition = index == 6 ? cardEdition : nil
        visits += 1
        lastClaimDay = Self.day(date)
        if index == 6 { cardEdition = nil }
        return (Self.coins[index], edition)
    }

    #if DEBUG
    static func verifyRules() {
        var progress = DailyRewardProgress()
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        assert(progress.claim(at: start)?.coins == 10)
        let locked = progress.cardEdition
        assert(progress.claim(at: start) == nil)
        assert(progress.claim(at: start.addingTimeInterval(-86_400)) == nil)
        // Missing days never resets the card; crossing months preserves its edition.
        for visit in 1...6 {
            let result = progress.claim(at: start.addingTimeInterval(Double(visit * 40) * 86_400))
            assert(result?.coins == Self.coins[visit])
            assert(result?.edition == (visit == 6 ? locked : nil))
        }
        assert(progress.visits == 7 && progress.nextIndex == 0 && progress.cardEdition == nil)
        assert(progress.claim(at: start.addingTimeInterval(241 * 86_400))?.coins == 10)
        print("[DailyRewards] rule checks passed: duplicate, clock rollback, missed days, month change, seven-day prize and new card")
    }
    #endif
}
