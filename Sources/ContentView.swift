import SwiftUI

public struct ContentView: View {
    @StateObject private var viewModel = DotabuffViewModel()
    
    public init() {
        print("🏗️ ContentView initialized")
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 25) {
                    headerSection
                    inputSection
                    resultsSection
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, max(20, (geometry.size.width - 1000) / 2))
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Dota 2 Player Stats")
    }
    
    private var headerSection: some View {
        VStack {
            Text("Dota 2 Player Statistics")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Enter player ID to view top 5 most played heroes")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var inputSection: some View {
        VStack(spacing: 15) {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    TextField("Enter Player ID (e.g., 44764606)", text: $viewModel.userID)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                        .frame(height: 40)
                        #if os(iOS)
                        .keyboardType(.default)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        #endif
                        .onChange(of: viewModel.userID) { newValue in
                            print("🔤 TextField onChange: '\(newValue)'")
                        }
                        .onAppear {
                            print("🔤 TextField appeared, current value: '\(viewModel.userID)'")
                        }
                    
                    Button(action: performSearch) {
                        Text("SEARCH")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(canPerformSearch ? Color.blue : Color.gray)
                            .cornerRadius(8)
                    }
                    .disabled(!canPerformSearch)
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Debug buttons to test binding
                HStack(spacing: 10) {
                    Button("Test: Set 44764606") {
                        print("🧪 Setting userID programmatically to '44764606'")
                        viewModel.userID = "44764606"
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(5)
                    
                    Button("Test: Clear") {
                        print("🧪 Clearing userID programmatically")
                        viewModel.userID = ""
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(5)
                    
                    Text("Current: '\(viewModel.userID)'")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if viewModel.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(0.8)
                    
                    Text("Fetching player data...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var canPerformSearch: Bool {
        let hasText = !viewModel.userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let notLoading = !viewModel.isLoading
        print("🔧 Button state - hasText: \(hasText), notLoading: \(notLoading), canSearch: \(hasText && notLoading)")
        return hasText && notLoading
    }
    
    private func performSearch() {
        guard canPerformSearch else { 
            print("❌ Search blocked - canPerformSearch: \(canPerformSearch)")
            return 
        }
        print("🔍 Search button triggered with userID: '\(viewModel.userID)'")
        viewModel.fetchPlayerStats()
    }
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            if !viewModel.heroStats.isEmpty {
                Text("Top 5 Most Played Heroes (Last Week)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 10)
                
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.heroStats, id: \.heroName) { stat in
                        HeroStatRow(heroStat: stat)
                    }
                }
                .onAppear {
                    print("📊 Results section appeared with \(viewModel.heroStats.count) hero stats")
                    for (index, stat) in viewModel.heroStats.enumerated() {
                        print("📊 Hero \(index + 1): \(stat.heroName) - \(stat.matchesPlayed) matches - \(stat.winRate)% WR")
                    }
                }
            } else if viewModel.errorMessage != nil {
                VStack {
                    Text(viewModel.errorMessage!)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct HeroStatRow: View {
    let heroStat: HeroStat
    
    var body: some View {
        HStack(spacing: 0) {
            // Hero info section - takes up more space
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(heroStat.heroName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                    
                    Text("\(heroStat.matchesPlayed) matches played")
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.7))
                }
                Spacer()
            }
            .frame(minWidth: 200)
            
            // Stats section - spread out more
            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("Win Rate")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.6))
                    
                    Text("\(heroStat.winRate, specifier: "%.1f")%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(heroStat.winRate >= 50 ? .green : .red)
                }
                .frame(minWidth: 80)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Period")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.6))
                    
                    Text(heroStat.dateRange)
                        .font(.caption2)
                        .foregroundColor(.black.opacity(0.7))
                        .multilineTextAlignment(.trailing)
                }
                .frame(minWidth: 120)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            print("🎭 HeroStatRow rendered - Hero: '\(heroStat.heroName)', Matches: \(heroStat.matchesPlayed), WinRate: \(heroStat.winRate)%")
        }
    }
}

#Preview {
    ContentView()
}