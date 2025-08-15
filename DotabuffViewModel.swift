import Foundation
import SwiftUI

@MainActor
class DotabuffViewModel: ObservableObject {
    @Published var userID: String = "" {
        didSet {
            print("🔧 ViewModel userID changed from '\(oldValue)' to '\(userID)'")
        }
    }
    @Published var heroStats: [HeroStat] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let service = DotabuffService.shared
    
    init() {
        print("🔧 DotabuffViewModel initialized with userID: '\(userID)'")
    }
    
    func fetchPlayerStats() {
        guard !userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a valid player ID"
            return
        }
        
        print("🚀 Starting fetch for player ID: \(userID)")
        isLoading = true
        errorMessage = nil
        heroStats = []
        
        Task {
            do {
                let matches = try await service.fetchPlayerMatches(userID: userID)
                print("📊 Raw matches received: \(matches.count)")
                
                let stats = calculateHeroStats(from: matches)
                print("📊 Hero stats calculated: \(stats.count)")
                
                for stat in stats {
                    print("  - \(stat.heroName): \(stat.matchesPlayed) matches, \(stat.winRate)% WR")
                }
                
                await MainActor.run {
                    self.heroStats = stats
                    self.isLoading = false
                    print("✅ UI updated with \(stats.count) hero stats")
                }
            } catch {
                print("❌ Error fetching player stats: \(error)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func calculateHeroStats(from matches: [MatchData]) -> [HeroStat] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let endDate = Date()
        let dateRange = "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
        
        let heroGroups = Dictionary(grouping: matches) { $0.heroName }
        
        var heroStats: [HeroStat] = []
        
        for (heroName, heroMatches) in heroGroups {
            let totalMatches = heroMatches.count
            let wins = heroMatches.filter { $0.result == .win }.count
            let winRate = totalMatches > 0 ? (Double(wins) / Double(totalMatches)) * 100 : 0
            
            let stat = HeroStat(
                heroName: heroName,
                matchesPlayed: totalMatches,
                winRate: winRate,
                dateRange: dateRange
            )
            heroStats.append(stat)
        }
        
        return heroStats
            .sorted { $0.matchesPlayed > $1.matchesPlayed }
            .prefix(5)
            .map { $0 }
    }
}