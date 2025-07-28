import SwiftUI

struct MatchesView: View {
    @StateObject private var viewModel = MatchesViewModel()
    @State private var showingCreateMatch = false
    @State private var selectedMatch: Match?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Active Matches Section
                    if !viewModel.activeMatches.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Active Matches")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.activeMatches) { match in
                                MatchCard(match: match) {
                                    selectedMatch = match
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Pending Matches Section
                    if !viewModel.pendingMatches.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Pending Matches")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.pendingMatches) { match in
                                MatchCard(match: match) {
                                    selectedMatch = match
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Completed Matches Section
                    if !viewModel.completedMatches.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Recent Results")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.completedMatches) { match in
                                MatchCard(match: match) {
                                    selectedMatch = match
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    if viewModel.allMatches.isEmpty {
                        EmptyStateView(
                            icon: "gamecontroller",
                            title: "No Matches Yet",
                            message: "Create a match or join one from a friend",
                            actionTitle: "Create Match",
                            action: { showingCreateMatch = true }
                        )
                        .padding(.top, 100)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Matches")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateMatch = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .refreshable {
                await viewModel.fetchMatches()
            }
            .sheet(isPresented: $showingCreateMatch) {
                CreateMatchView()
            }
            .sheet(item: $selectedMatch) { match in
                MatchDetailView(match: match)
            }
            .task {
                await viewModel.fetchMatches()
            }
        }
    }
}

struct MatchCard: View {
    let match: Match
    let action: () -> Void
    
    var statusColor: Color {
        switch match.status {
        case .pending: return .orange
        case .active: return .blue
        case .voting: return .purple
        case .disputed: return .red
        case .completed: return .green
        case .cancelled: return .gray
        }
    }
    
    var statusIcon: String {
        switch match.status {
        case .pending: return "clock.fill"
        case .active: return "play.circle.fill"
        case .voting: return "checkmark.circle"
        case .disputed: return "exclamationmark.triangle.fill"
        case .completed: return "trophy.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(match.activityType)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Image(systemName: statusIcon)
                                .font(.caption)
                            Text(match.status.rawValue.capitalized)
                                .font(.caption)
                        }
                        .foregroundColor(statusColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(match.totalPot) tokens")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(match.participants?.count ?? 0) players")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if match.isPremiumOnly {
                    Label("Premium Only", systemImage: "crown.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
                
                HStack {
                    if let participants = match.participants?.prefix(3) {
                        HStack(spacing: -10) {
                            ForEach(Array(participants.enumerated()), id: \.offset) { _, participant in
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Text(participant.user?.username.prefix(1).uppercased() ?? "?")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                    )
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Text(match.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

class MatchesViewModel: ObservableObject {
    @Published var allMatches: [Match] = []
    @Published var isLoading = false
    @Published var error: String?
    
    var activeMatches: [Match] {
        allMatches.filter { $0.status == .active || $0.status == .voting }
    }
    
    var pendingMatches: [Match] {
        allMatches.filter { $0.status == .pending }
    }
    
    var completedMatches: [Match] {
        allMatches.filter { $0.status == .completed || $0.status == .cancelled }
    }
    
    func fetchMatches() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let matches = try await SupabaseManager.shared.fetchMatches()
            await MainActor.run {
                self.allMatches = matches
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
}