import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var walletManager: WalletManager
    @EnvironmentObject var authManager: AuthManager
    @State private var showingCreateMatch = false
    @State private var selectedMatch: Match?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    // Welcome Header
                    WelcomeHeader(username: authManager.currentUser?.username ?? "")
                    
                    // Quick Stats
                    QuickStatsView(
                        balance: walletManager.totalBalance,
                        activeMatches: viewModel.activeMatchesCount,
                        winRate: viewModel.winRate
                    )
                    
                    // Quick Actions
                    QuickActionsView(
                        showingCreateMatch: $showingCreateMatch,
                        onJoinMatch: {
                            // Navigate to matches tab
                        }
                    )
                    
                    // Active Matches
                    if !viewModel.activeMatches.isEmpty {
                        ActiveMatchesSection(
                            matches: viewModel.activeMatches,
                            selectedMatch: $selectedMatch
                        )
                    }
                    
                    // Friend Activity
                    if !viewModel.friendActivities.isEmpty {
                        FriendActivitySection(activities: viewModel.friendActivities)
                    }
                    
                    // Promotional Banner
                    if !authManager.currentUser?.isPremium ?? true {
                        PremiumPromoBanner()
                    }
                }
                .padding(.vertical)
            }
            .navigationBarHidden(true)
            .refreshable {
                await viewModel.refresh()
                await walletManager.fetchBalance()
            }
            .sheet(isPresented: $showingCreateMatch) {
                CreateMatchView()
            }
            .sheet(item: $selectedMatch) { match in
                MatchDetailView(match: match)
            }
            .task {
                await viewModel.loadDashboard()
            }
        }
    }
}

struct WelcomeHeader: View {
    let username: String
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(greeting)
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Text("\(username)!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            NotificationBell()
        }
        .padding(.horizontal)
    }
}

struct NotificationBell: View {
    @State private var hasNotifications = true
    @State private var showingNotifications = false
    
    var body: some View {
        Button {
            showingNotifications = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.title2)
                    .foregroundColor(.primary)
                
                if hasNotifications {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .offset(x: 4, y: -4)
                }
            }
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView()
        }
    }
}

struct QuickStatsView: View {
    let balance: Int
    let activeMatches: Int
    let winRate: Double
    
    var body: some View {
        HStack(spacing: 15) {
            StatCard(
                title: "Balance",
                value: "\(balance)",
                icon: "dollarsign",
                color: .green
            )
            
            StatCard(
                title: "Active",
                value: "\(activeMatches)",
                icon: "gamecontroller.fill",
                color: .blue
            )
            
            StatCard(
                title: "Win Rate",
                value: "\(Int(winRate * 100))%",
                icon: "trophy.fill",
                color: .yellow
            )
        }
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .contentTransition(.numericText())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

struct QuickActionsView: View {
    @Binding var showingCreateMatch: Bool
    let onJoinMatch: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            Button {
                showingCreateMatch = true
            } label: {
                Label("Create Match", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            
            Button {
                onJoinMatch()
            } label: {
                Label("Join Match", systemImage: "person.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(.horizontal)
    }
}

struct ActiveMatchesSection: View {
    let matches: [Match]
    @Binding var selectedMatch: Match?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Your Active Matches")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: MatchesView()) {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(matches) { match in
                        CompactMatchCard(match: match) {
                            selectedMatch = match
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct CompactMatchCard: View {
    let match: Match
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: match.activity?.iconName ?? "gamecontroller.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    Spacer()
                    
                    if match.status == .voting {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(.orange)
                    }
                }
                
                Text(match.activityType)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack {
                    Label("\(match.totalPot)", systemImage: "dollarsign")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(match.status.rawValue.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor(for: match.status))
                }
            }
            .padding()
            .frame(width: 180)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statusColor(for status: Match.MatchStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .active: return .blue
        case .voting: return .purple
        case .disputed: return .red
        case .completed: return .green
        case .cancelled: return .gray
        }
    }
}

struct FriendActivitySection: View {
    let activities: [FriendActivity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Friend Activity")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 10) {
                ForEach(activities) { activity in
                    FriendActivityRow(activity: activity)
                        .padding(.horizontal)
                }
            }
        }
    }
}

struct FriendActivityRow: View {
    let activity: FriendActivity
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(activity.friendUsername.prefix(1).uppercased())
                        .fontWeight(.bold)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.message)
                    .font(.subheadline)
                
                Text(activity.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let actionIcon = activity.actionIcon {
                Image(systemName: actionIcon)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 5)
    }
}

struct PremiumPromoBanner: View {
    @State private var showingPremium = false
    
    var body: some View {
        Button {
            showingPremium = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                        Text("Upgrade to Bet+")
                            .fontWeight(.bold)
                    }
                    
                    Text("No fees • Exclusive games • More rewards")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(15)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingPremium) {
            PremiumView()
        }
    }
}

struct FriendActivity: Identifiable {
    let id = UUID()
    let friendUsername: String
    let message: String
    let timestamp: Date
    let actionIcon: String?
}

class HomeViewModel: ObservableObject {
    @Published var activeMatches: [Match] = []
    @Published var friendActivities: [FriendActivity] = []
    @Published var winRate: Double = 0.0
    @Published var isLoading = false
    
    var activeMatchesCount: Int {
        activeMatches.count
    }
    
    func loadDashboard() async {
        isLoading = true
        defer { isLoading = false }
        
        // Load active matches
        await loadActiveMatches()
        
        // Load friend activities
        await loadFriendActivities()
        
        // Calculate win rate
        await calculateWinRate()
    }
    
    func refresh() async {
        await loadDashboard()
    }
    
    private func loadActiveMatches() async {
        do {
            let matches = try await SupabaseManager.shared.fetchMatches(status: .active)
            await MainActor.run {
                self.activeMatches = matches
            }
        } catch {
            print("Error loading matches: \(error)")
        }
    }
    
    private func loadFriendActivities() async {
        // Simulate loading friend activities
        await MainActor.run {
            self.friendActivities = [
                FriendActivity(
                    friendUsername: "john_doe",
                    message: "Won a Chess match!",
                    timestamp: Date().addingTimeInterval(-1800),
                    actionIcon: "trophy.fill"
                ),
                FriendActivity(
                    friendUsername: "jane_smith",
                    message: "Created a new Poker game",
                    timestamp: Date().addingTimeInterval(-3600),
                    actionIcon: "plus.circle.fill"
                ),
                FriendActivity(
                    friendUsername: "mike_wilson",
                    message: "Joined your Basketball bet",
                    timestamp: Date().addingTimeInterval(-7200),
                    actionIcon: "person.badge.plus"
                )
            ]
        }
    }
    
    private func calculateWinRate() async {
        // Calculate win rate from match history
        await MainActor.run {
            self.winRate = 0.67 // 67% win rate
        }
    }
}