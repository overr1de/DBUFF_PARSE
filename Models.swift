import Foundation

struct HeroStat {
    let heroName: String
    let matchesPlayed: Int
    let winRate: Double
    let dateRange: String
}

struct MatchData {
    let heroName: String
    let result: MatchResult
    let date: Date
}

enum MatchResult {
    case win
    case loss
}

struct PlayerData {
    let userID: String
    let matches: [MatchData]
    let dateRange: String
}