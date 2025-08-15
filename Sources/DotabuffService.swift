import Foundation
import SwiftSoup

class DotabuffService {
    static let shared = DotabuffService()
    private init() {}
    
    func fetchPlayerMatches(userID: String) async throws -> [MatchData] {
        let urlString = "https://www.dotabuff.com/players/\(userID)/matches"
        print("🌐 Fetching URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(urlString)")
            throw DotabuffError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.5", forHTTPHeaderField: "Accept-Language")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("1", forHTTPHeaderField: "DNT")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue("1", forHTTPHeaderField: "Upgrade-Insecure-Requests")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 HTTP Status: \(httpResponse.statusCode)")
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            print("❌ Failed to decode HTML response")
            throw DotabuffError.invalidResponse
        }
        
        print("📄 HTML length: \(html.count) characters")
        print("📄 HTML preview (first 500 chars):")
        print(String(html.prefix(500)))
        
        return try parseMatches(from: html)
    }
    
    private func parseMatches(from html: String) throws -> [MatchData] {
        print("🔍 Starting HTML parsing...")
        let doc = try SwiftSoup.parse(html)
        
        // Try multiple selectors for match rows
        print("🔍 Looking for match rows with multiple selectors...")
        var matchRows = try doc.select("tbody tr")
        if matchRows.isEmpty {
            matchRows = try doc.select("table tr")
        }
        if matchRows.isEmpty {
            matchRows = try doc.select(".matches-tab table tr")
        }
        if matchRows.isEmpty {
            matchRows = try doc.select(".match-row")
        }
        print("🔍 Found \(matchRows.count) potential match rows")
        
        var matches: [MatchData] = []
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        print("🗓️ Filtering matches from: \(oneWeekAgo)")
        
        for (index, row) in matchRows.enumerated() {
            print("🔍 Processing row \(index + 1)...")
            
            do {
                // Try multiple selectors for hero - focus on hero name not abilities
                let heroSelectors = [
                    ".cell-xlarge img", // Main hero image
                    ".r-tab-hero img", // Hero tab image
                    "td:first-child img", // First cell image
                    ".match-cell--hero img", // Hero cell image
                    ".cell-hero img", // Hero cell
                    "td img[src*='heroes']", // Images with heroes in src
                    "img[src*='/heroes/']" // Direct hero image path
                ]
                
                var heroElement: Element?
                for selector in heroSelectors {
                    let elements = try row.select(selector)
                    for element in elements {
                        // Check if this is actually a hero image, not ability/modifier
                        let src = try element.attr("src")
                        if src.contains("/heroes/") || src.contains("hero") {
                            heroElement = element
                            break
                        }
                    }
                    if heroElement != nil { break }
                }
                
                // Try multiple selectors for result - focus on win/loss indicators
                let resultSelectors = [
                    ".match-result", // Direct result class
                    ".cell-result", // Result cell
                    ".match-cell--result", // Match result cell
                    "td:nth-child(2)", // Second column (often result)
                    "td:nth-child(3)", // Third column (backup)
                    ".won", // Win indicator
                    ".lost", // Loss indicator
                    "td[class*='won']", // Any td with 'won' in class
                    "td[class*='lost']", // Any td with 'lost' in class
                    "td", // Fallback to any td
                ]
                
                var resultElement: Element?
                var resultText: String = ""
                
                for selector in resultSelectors {
                    let elements = try row.select(selector)
                    for element in elements {
                        let text = try element.text().lowercased()
                        let className = try element.attr("class").lowercased()
                        
                        // Check if this element contains win/loss information
                        if text.contains("won") || text.contains("victory") || text.contains("win") ||
                           text.contains("lost") || text.contains("defeat") || text.contains("loss") ||
                           className.contains("won") || className.contains("lost") ||
                           className.contains("victory") || className.contains("defeat") {
                            resultElement = element
                            resultText = text
                            break
                        }
                    }
                    if resultElement != nil { break }
                }
                
                // If still no result found, try looking for color indicators or icons
                if resultElement == nil {
                    let colorSelectors = [
                        "td[style*='green']", // Green background for wins
                        "td[style*='red']", // Red background for losses
                        ".text-success", // Success text (wins)
                        ".text-danger", // Danger text (losses)
                        ".text-green", // Green text
                        ".text-red" // Red text
                    ]
                    
                    for selector in colorSelectors {
                        resultElement = try row.select(selector).first()
                        if resultElement != nil {
                            resultText = try resultElement?.text().lowercased() ?? ""
                            break
                        }
                    }
                }
                
                let dateElement = try row.select("time").first()
                
                print("  Hero element found: \(heroElement != nil)")
                print("  Result element found: \(resultElement != nil)")
                print("  Result text: '\(resultText)'")
                print("  Date element found: \(dateElement != nil)")
                
                // Print more detailed result debugging
                if resultElement != nil {
                    let className = try resultElement?.attr("class") ?? ""
                    print("  🏆 Result element class: '\(className)'")
                    print("  🏆 Result element text: '\(try resultElement?.text() ?? "")'")
                }
                
                // Print row HTML for debugging if no elements found
                if heroElement == nil && resultElement == nil && dateElement == nil {
                    print("  🔍 Row HTML: \(try row.outerHtml())")
                }
                
                var heroName: String?
                if let hero = heroElement {
                    let src = try hero.attr("src")
                    print("  🎭 Hero image src: \(src)")
                    
                    // First try alt attribute (most reliable for hero names)
                    heroName = try hero.attr("alt")
                    print("  🎭 Hero alt text: \(heroName ?? "nil")")
                    
                    // If alt is empty or contains ability/modifier terms, try title
                    if heroName?.isEmpty != false || isAbilityName(heroName) {
                        heroName = try hero.attr("title")
                        print("  🎭 Hero title: \(heroName ?? "nil")")
                    }
                    
                    // If still not good, try to extract from src path
                    if heroName?.isEmpty != false || isAbilityName(heroName) {
                        heroName = extractHeroNameFromPath(src)
                        print("  🎭 Hero from path: \(heroName ?? "nil")")
                    }
                    
                    // Clean up the hero name if it contains ability indicators
                    if let cleanName = heroName {
                        heroName = cleanHeroName(cleanName)
                        print("  🎭 Cleaned hero name: \(heroName ?? "nil")")
                    }
                }
                
                guard let finalHeroName = heroName,
                      resultElement != nil,
                      let dateString = try dateElement?.attr("datetime") else {
                    print("  ❌ Missing data - Hero: \(heroName ?? "nil"), Result element: \(resultElement != nil), Date: \(try? dateElement?.attr("datetime") ?? "nil")")
                    continue
                }
                
                // Determine win/loss from multiple sources
                let finalResultText = !resultText.isEmpty ? resultText : (try resultElement?.text().lowercased() ?? "")
                let resultClass = try resultElement?.attr("class").lowercased() ?? ""
                
                print("  ✅ Found match - Hero: \(finalHeroName), Result text: '\(finalResultText)', Result class: '\(resultClass)', Date: \(dateString)")
                
                let matchDate = parseDate(from: dateString)
                
                if matchDate >= oneWeekAgo {
                    // Enhanced win/loss detection
                    let isWin = isMatchWon(resultText: finalResultText, resultClass: resultClass)
                    let result: MatchResult = isWin ? .win : .loss
                    
                    let match = MatchData(heroName: finalHeroName, result: result, date: matchDate)
                    matches.append(match)
                    print("  ✅ Added to matches (within last week) - Result: \(isWin ? "WIN" : "LOSS")")
                } else {
                    print("  ⏰ Match too old, skipping")
                }
            } catch {
                print("  ❌ Error parsing row: \(error)")
                continue
            }
        }
        
        print("🎯 Total matches found: \(matches.count)")
        return matches
    }
    
    private func parseDate(from dateString: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString) ?? Date()
    }
    
    private func isAbilityName(_ name: String?) -> Bool {
        guard let name = name?.lowercased() else { return true }
        
        // Common ability/modifier terms that indicate this is not a hero name
        let abilityTerms = [
            "bladestorm", "omnislash", "blade fury", "healing ward",
            "berserker", "battle hunger", "culling blade",
            "hook", "rot", "dismember",
            "fissure", "enchant totem", "echo slam",
            "power shot", "windrun", "focus fire",
            "mana burn", "blink", "reality rift",
            "telekinesis", "spell steal", "invoke",
            "storm bolt", "thunder clap", "god's strength"
        ]
        
        return abilityTerms.contains { name.contains($0) }
    }
    
    private func extractHeroNameFromPath(_ path: String) -> String? {
        // Extract hero name from image path like "/assets/heroes/juggernaut_full.png"
        let components = path.components(separatedBy: "/")
        for component in components {
            if component.contains("hero") || component.contains(".png") || component.contains(".jpg") {
                let heroName = component
                    .replacingOccurrences(of: "_full", with: "")
                    .replacingOccurrences(of: "_icon", with: "")
                    .replacingOccurrences(of: "_small", with: "")
                    .replacingOccurrences(of: ".png", with: "")
                    .replacingOccurrences(of: ".jpg", with: "")
                    .replacingOccurrences(of: "_", with: " ")
                    .capitalized
                
                if !heroName.isEmpty && heroName.count > 2 {
                    return heroName
                }
            }
        }
        return nil
    }
    
    private func cleanHeroName(_ name: String) -> String {
        var cleanName = name
        
        // Remove common ability suffixes/prefixes
        let cleanPatterns = [
            " - .*", // Remove everything after " - "
            "\\(.*\\)", // Remove parentheses content
            "Ability: ", // Remove ability prefix
            "Spell: ", // Remove spell prefix
        ]
        
        for pattern in cleanPatterns {
            cleanName = cleanName.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        
        return cleanName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func isMatchWon(resultText: String, resultClass: String) -> Bool {
        let text = resultText.lowercased()
        let className = resultClass.lowercased()
        
        // Check for win indicators
        let winIndicators = ["won", "victory", "win", "radiant victory", "dire victory"]
        let lossIndicators = ["lost", "defeat", "loss"]
        
        // Check text content
        for indicator in winIndicators {
            if text.contains(indicator) {
                print("    🎯 WIN detected from text: '\(indicator)' in '\(text)'")
                return true
            }
        }
        
        for indicator in lossIndicators {
            if text.contains(indicator) {
                print("    🎯 LOSS detected from text: '\(indicator)' in '\(text)'")
                return false
            }
        }
        
        // Check class names
        if className.contains("won") || className.contains("victory") || className.contains("win") {
            print("    🎯 WIN detected from class: '\(className)'")
            return true
        }
        
        if className.contains("lost") || className.contains("defeat") || className.contains("loss") {
            print("    🎯 LOSS detected from class: '\(className)'")
            return false
        }
        
        // Default to loss if unclear
        print("    ⚠️ Could not determine win/loss from text: '\(text)' or class: '\(className)' - defaulting to LOSS")
        return false
    }
}

enum DotabuffError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid player ID or URL"
        case .invalidResponse:
            return "Unable to fetch player data"
        case .parseError:
            return "Unable to parse match data"
        }
    }
}