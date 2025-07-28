import SwiftUI

struct SocialView: View {
    @StateObject private var viewModel = SocialViewModel()
    @State private var searchText = ""
    @State private var showingAddFriend = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Tab Bar
                HStack(spacing: 0) {
                    TabButton(title: "Friends", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    
                    TabButton(title: "Requests", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                    
                    TabButton(title: "Leaderboard", isSelected: selectedTab == 2) {
                        selectedTab = 2
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                TabView(selection: $selectedTab) {
                    FriendsListView(viewModel: viewModel, searchText: $searchText)
                        .tag(0)
                    
                    FriendRequestsView(viewModel: viewModel)
                        .tag(1)
                    
                    LeaderboardView()
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Social")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddFriend = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadSocialData()
            }
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Rectangle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct FriendsListView: View {
    @ObservedObject var viewModel: SocialViewModel
    @Binding var searchText: String
    
    var filteredFriends: [User] {
        if searchText.isEmpty {
            return viewModel.friends
        }
        return viewModel.friends.filter {
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ScrollView {
            if filteredFriends.isEmpty {
                EmptyStateView(
                    icon: "person.2.slash",
                    title: searchText.isEmpty ? "No Friends Yet" : "No Results",
                    message: searchText.isEmpty ? "Add friends to start competing!" : "Try a different search",
                    actionTitle: searchText.isEmpty ? "Add Friends" : nil,
                    action: searchText.isEmpty ? { } : nil
                )
                .padding(.top, 100)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(filteredFriends) { friend in
                        FriendRow(friend: friend, viewModel: viewModel)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
    }
}

struct FriendRow: View {
    let friend: User
    let viewModel: SocialViewModel
    @State private var showingProfile = false
    @State private var showingChallenge = false
    
    var body: some View {
        HStack(spacing: 15) {
            // Profile Picture
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(friend.username.prefix(2).uppercased())
                        .fontWeight(.bold)
                )
                .onTapGesture {
                    showingProfile = true
                }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(friend.username)
                        .fontWeight(.semibold)
                    
                    if friend.isPremium {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                
                HStack(spacing: 15) {
                    Label("\(friend.totalBalance)", systemImage: "dollarsign")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let winRate = viewModel.friendStats[friend.id]?.winRate {
                        Label("\(Int(winRate * 100))% wins", systemImage: "trophy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Button {
                showingChallenge = true
            } label: {
                Text("Challenge")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .cornerRadius(15)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .sheet(isPresented: $showingProfile) {
            FriendProfileView(friend: friend)
        }
        .sheet(isPresented: $showingChallenge) {
            ChallengeFriendView(friend: friend)
        }
    }
}

struct FriendRequestsView: View {
    @ObservedObject var viewModel: SocialViewModel
    
    var body: some View {
        ScrollView {
            if viewModel.pendingRequests.isEmpty && viewModel.sentRequests.isEmpty {
                EmptyStateView(
                    icon: "envelope.open",
                    title: "No Requests",
                    message: "You don't have any pending friend requests"
                )
                .padding(.top, 100)
            } else {
                VStack(spacing: 20) {
                    if !viewModel.pendingRequests.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Pending Requests")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.pendingRequests) { request in
                                PendingRequestRow(request: request, viewModel: viewModel)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    if !viewModel.sentRequests.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Sent Requests")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.sentRequests) { request in
                                SentRequestRow(request: request, viewModel: viewModel)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
    }
}

struct PendingRequestRow: View {
    let request: Friendship
    let viewModel: SocialViewModel
    @State private var isProcessing = false
    
    var body: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(request.requester?.username.prefix(2).uppercased() ?? "??")
                        .fontWeight(.bold)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(request.requester?.username ?? "Unknown")
                    .fontWeight(.semibold)
                
                Text("Sent \(request.createdAt, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                Button {
                    Task {
                        isProcessing = true
                        await viewModel.acceptRequest(request)
                        isProcessing = false
                    }
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .frame(width: 35, height: 35)
                        .background(Color.green)
                        .clipShape(Circle())
                }
                .disabled(isProcessing)
                
                Button {
                    Task {
                        isProcessing = true
                        await viewModel.declineRequest(request)
                        isProcessing = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .frame(width: 35, height: 35)
                        .background(Color.red)
                        .clipShape(Circle())
                }
                .disabled(isProcessing)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

struct SentRequestRow: View {
    let request: Friendship
    let viewModel: SocialViewModel
    
    var body: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(request.recipient?.username.prefix(2).uppercased() ?? "??")
                        .fontWeight(.bold)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(request.recipient?.username ?? "Unknown")
                    .fontWeight(.semibold)
                
                Text("Sent \(request.createdAt, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("Pending")
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(10)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    @State private var timeFrame = TimeFrame.weekly
    
    enum TimeFrame: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case allTime = "All Time"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time Frame Picker
                Picker("Time Frame", selection: $timeFrame) {
                    ForEach(TimeFrame.allCases, id: \.self) { frame in
                        Text(frame.rawValue).tag(frame)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Top 3 Players
                if viewModel.leaderboard.count >= 3 {
                    HStack(alignment: .bottom, spacing: 20) {
                        // 2nd Place
                        PodiumView(
                            player: viewModel.leaderboard[1],
                            position: 2,
                            height: 120
                        )
                        
                        // 1st Place
                        PodiumView(
                            player: viewModel.leaderboard[0],
                            position: 1,
                            height: 150
                        )
                        
                        // 3rd Place
                        PodiumView(
                            player: viewModel.leaderboard[2],
                            position: 3,
                            height: 100
                        )
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                }
                
                // Rest of Leaderboard
                VStack(spacing: 10) {
                    ForEach(Array(viewModel.leaderboard.enumerated()), id: \.element.id) { index, player in
                        if index >= 3 {
                            LeaderboardRow(player: player, position: index + 1)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .onChange(of: timeFrame) { _ in
            Task {
                await viewModel.loadLeaderboard(for: timeFrame)
            }
        }
        .task {
            await viewModel.loadLeaderboard(for: timeFrame)
        }
    }
}

struct PodiumView: View {
    let player: LeaderboardEntry
    let position: Int
    let height: CGFloat
    
    var medal: String {
        switch position {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 5) {
                Text(medal)
                    .font(.title)
                
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(player.username.prefix(2).uppercased())
                            .fontWeight(.bold)
                    )
                
                Text(player.username)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text("\(player.winnings) tokens")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Rectangle()
                .fill(
                    position == 1 ? Color.yellow :
                    position == 2 ? Color.gray :
                    Color.orange
                )
                .frame(height: height)
                .cornerRadius(10, corners: [.topLeft, .topRight])
        }
    }
}

struct LeaderboardRow: View {
    let player: LeaderboardEntry
    let position: Int
    
    var body: some View {
        HStack(spacing: 15) {
            Text("\(position)")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 30)
            
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(player.username.prefix(2).uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(player.username)
                    .fontWeight(.medium)
                
                Text("\(player.matchesWon) wins")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(player.winnings) tokens")
                    .fontWeight(.semibold)
                
                Text("\(Int(player.winRate * 100))% win rate")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

struct AddFriendView: View {
    let viewModel: SocialViewModel
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var searchMethod = SearchMethod.username
    @State private var searchResults: [User] = []
    @State private var isSearching = false
    
    enum SearchMethod: String, CaseIterable {
        case username = "Username"
        case email = "Email"
        case phone = "Phone"
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Search by", selection: $searchMethod) {
                    ForEach(SearchMethod.allCases, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                CustomTextField(
                    placeholder: "Enter \(searchMethod.rawValue.lowercased())",
                    text: $searchText,
                    icon: searchMethod == .email ? "envelope" : searchMethod == .phone ? "phone" : "person",
                    keyboardType: searchMethod == .email ? .emailAddress : searchMethod == .phone ? .phonePad : .default
                )
                .padding(.horizontal)
                
                if isSearching {
                    ProgressView()
                        .padding()
                } else if !searchResults.isEmpty {
                    List(searchResults) { user in
                        UserSearchRow(user: user, viewModel: viewModel)
                    }
                    .listStyle(PlainListStyle())
                } else if !searchText.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No Results",
                        message: "Try searching with a different \(searchMethod.rawValue.lowercased())"
                    )
                    .padding(.top, 50)
                }
                
                Spacer()
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Search") {
                        Task {
                            await search()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(searchText.isEmpty)
                }
            }
        }
    }
    
    private func search() async {
        isSearching = true
        defer { isSearching = false }
        
        // Simulate search
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Mock results
        searchResults = [
            User(
                id: UUID(),
                email: "test@example.com",
                phone: nil,
                username: "test_user",
                totalBalance: 1000,
                withdrawableBalance: 800,
                subscriptionStatus: .free,
                subscriptionExpiresAt: nil,
                premiumTrialUses: [:],
                region: "US",
                ageVerified: true,
                createdAt: Date()
            )
        ]
    }
}

struct UserSearchRow: View {
    let user: User
    let viewModel: SocialViewModel
    @State private var requestSent = false
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(user.username.prefix(2).uppercased())
                        .fontWeight(.bold)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.username)
                    .fontWeight(.semibold)
                
                Text("Member since \(user.createdAt, formatter: DateFormatter.monthYear)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                Task {
                    await sendRequest()
                }
            } label: {
                if requestSent {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                } else {
                    Text("Add")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor)
                        .cornerRadius(15)
                }
            }
            .disabled(requestSent)
        }
        .padding(.vertical, 8)
    }
    
    private func sendRequest() async {
        do {
            try await viewModel.sendFriendRequest(to: user.id)
            requestSent = true
            HapticManager.success()
        } catch {
            HapticManager.error()
        }
    }
}

struct FriendProfileView: View {
    let friend: User
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 15) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(friend.username.prefix(2).uppercased())
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                            )
                        
                        Text(friend.username)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if friend.isPremium {
                            Label("Bet+ Member", systemImage: "crown.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.yellow.opacity(0.2))
                                .cornerRadius(15)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        StatBox(title: "Balance", value: "\(friend.totalBalance)", icon: "dollarsign")
                        StatBox(title: "Matches", value: "42", icon: "gamecontroller")
                        StatBox(title: "Win Rate", value: "67%", icon: "trophy")
                        StatBox(title: "Member Since", value: "Jan 2024", icon: "calendar")
                    }
                    .padding(.horizontal)
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Recent Activity")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 10) {
                            ActivityItem(icon: "trophy.fill", text: "Won Chess match", time: "2 hours ago", color: .green)
                            ActivityItem(icon: "gamecontroller.fill", text: "Started Poker game", time: "5 hours ago", color: .blue)
                            ActivityItem(icon: "person.badge.plus", text: "Joined Basketball bet", time: "1 day ago", color: .orange)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
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

struct ActivityItem: View {
    let icon: String
    let text: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
            
            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 5)
    }
}

struct ChallengeFriendView: View {
    let friend: User
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        CreateMatchView()
            .onAppear {
                // Pre-select friend as invited
            }
    }
}

struct FriendStats {
    let winRate: Double
    let totalMatches: Int
    let totalWinnings: Int
}

struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let username: String
    let winnings: Int
    let matchesWon: Int
    let winRate: Double
}

class SocialViewModel: ObservableObject {
    @Published var friends: [User] = []
    @Published var pendingRequests: [Friendship] = []
    @Published var sentRequests: [Friendship] = []
    @Published var friendStats: [UUID: FriendStats] = [:]
    @Published var isLoading = false
    
    func loadSocialData() async {
        isLoading = true
        defer { isLoading = false }
        
        await loadFriends()
        await loadRequests()
        await loadFriendStats()
    }
    
    private func loadFriends() async {
        do {
            friends = try await SupabaseManager.shared.fetchFriends()
        } catch {
            print("Error loading friends: \(error)")
        }
    }
    
    private func loadRequests() async {
        // Load pending and sent friend requests
        // Simulated data for now
        pendingRequests = []
        sentRequests = []
    }
    
    private func loadFriendStats() async {
        // Load stats for each friend
        for friend in friends {
            friendStats[friend.id] = FriendStats(
                winRate: 0.65,
                totalMatches: 42,
                totalWinnings: 2500
            )
        }
    }
    
    func sendFriendRequest(to userId: UUID) async throws {
        try await SupabaseManager.shared.sendFriendRequest(to: userId)
        await loadRequests()
    }
    
    func acceptRequest(_ request: Friendship) async {
        do {
            try await SupabaseManager.shared.acceptFriendRequest(request.id)
            await loadSocialData()
            HapticManager.success()
        } catch {
            print("Error accepting request: \(error)")
            HapticManager.error()
        }
    }
    
    func declineRequest(_ request: Friendship) async {
        // Decline friend request
        await loadRequests()
        HapticManager.impact(.light)
    }
}

class LeaderboardViewModel: ObservableObject {
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var isLoading = false
    
    func loadLeaderboard(for timeFrame: LeaderboardView.TimeFrame) async {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate loading leaderboard data
        await MainActor.run {
            self.leaderboard = [
                LeaderboardEntry(username: "champion_99", winnings: 15000, matchesWon: 45, winRate: 0.82),
                LeaderboardEntry(username: "pro_gamer", winnings: 12500, matchesWon: 38, winRate: 0.75),
                LeaderboardEntry(username: "lucky_7", winnings: 10000, matchesWon: 32, winRate: 0.71),
                LeaderboardEntry(username: "skilled_one", winnings: 8500, matchesWon: 28, winRate: 0.68),
                LeaderboardEntry(username: "rising_star", winnings: 7200, matchesWon: 25, winRate: 0.65),
                LeaderboardEntry(username: "steady_win", winnings: 6000, matchesWon: 22, winRate: 0.62),
                LeaderboardEntry(username: "game_master", winnings: 5500, matchesWon: 20, winRate: 0.60)
            ]
        }
    }
}

extension DateFormatter {
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}