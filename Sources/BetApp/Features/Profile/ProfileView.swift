import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var walletManager: WalletManager
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    @State private var showingPremium = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    // Profile Header
                    ProfileHeaderView(
                        user: authManager.currentUser,
                        stats: viewModel.userStats,
                        onEditProfile: { showingEditProfile = true }
                    )
                    
                    // Premium Banner
                    if !(authManager.currentUser?.isPremium ?? false) {
                        PremiumBanner(onTap: { showingPremium = true })
                    }
                    
                    // Stats Overview
                    StatsOverviewView(stats: viewModel.userStats)
                    
                    // Menu Options
                    VStack(spacing: 0) {
                        MenuRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Match History",
                            showBadge: false
                        ) {
                            // Navigate to match history
                        }
                        
                        MenuRow(
                            icon: "banknote",
                            title: "Transaction History",
                            showBadge: false
                        ) {
                            // Navigate to transactions
                        }
                        
                        MenuRow(
                            icon: "crown.fill",
                            title: "Bet+ Subscription",
                            showBadge: !(authManager.currentUser?.isPremium ?? false),
                            badgeColor: .yellow
                        ) {
                            showingPremium = true
                        }
                        
                        MenuRow(
                            icon: "bell",
                            title: "Notifications",
                            showBadge: false
                        ) {
                            // Navigate to notification settings
                        }
                        
                        MenuRow(
                            icon: "shield.checkered",
                            title: "Security",
                            showBadge: false
                        ) {
                            // Navigate to security settings
                        }
                        
                        MenuRow(
                            icon: "questionmark.circle",
                            title: "Help & Support",
                            showBadge: false
                        ) {
                            // Navigate to help
                        }
                        
                        MenuRow(
                            icon: "gearshape",
                            title: "Settings",
                            showBadge: false
                        ) {
                            showingSettings = true
                        }
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // Sign Out Button
                    Button {
                        Task {
                            await authManager.signOut()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.left.circle")
                            Text("Sign Out")
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(15)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showingPremium) {
                PremiumView()
            }
            .task {
                await viewModel.loadUserStats()
            }
        }
    }
}

struct ProfileHeaderView: View {
    let user: User?
    let stats: UserStats?
    let onEditProfile: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile Picture
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(user?.username.prefix(2).uppercased() ?? "??")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    )
                
                Button(action: onEditProfile) {
                    Image(systemName: "camera.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                }
                .offset(x: 5, y: 5)
            }
            
            // User Info
            VStack(spacing: 8) {
                HStack {
                    Text(user?.username ?? "Username")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if user?.isPremium ?? false {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                    }
                }
                
                Text(user?.email ?? "email@example.com")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let region = user?.region {
                    Label(region, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Quick Stats
            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Text("\(stats?.totalMatches ?? 0)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Matches")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(stats?.wins ?? 0)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Wins")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(Int((stats?.winRate ?? 0) * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Win Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(20)
        .padding(.horizontal)
    }
}

struct PremiumBanner: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                        Text("Unlock Bet+")
                            .fontWeight(.bold)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("No processing fees", systemImage: "checkmark")
                        Label("Exclusive activities", systemImage: "checkmark")
                        Label("Priority support", systemImage: "checkmark")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    Text("$4.99")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("/month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.yellow.opacity(0.2), Color.orange.opacity(0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.yellow, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

struct StatsOverviewView: View {
    let stats: UserStats?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Performance Overview")
                .font(.headline)
            
            VStack(spacing: 12) {
                StatsRow(
                    title: "Total Earnings",
                    value: "\(stats?.totalEarnings ?? 0) tokens",
                    icon: "dollarsign.circle.fill",
                    color: .green
                )
                
                StatsRow(
                    title: "Biggest Win",
                    value: "\(stats?.biggestWin ?? 0) tokens",
                    icon: "trophy.fill",
                    color: .yellow
                )
                
                StatsRow(
                    title: "Win Streak",
                    value: "\(stats?.currentStreak ?? 0) matches",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatsRow(
                    title: "Favorite Activity",
                    value: stats?.favoriteActivity ?? "None",
                    icon: "star.fill",
                    color: .purple
                )
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(15)
        }
        .padding(.horizontal)
    }
}

struct StatsRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
            }
            
            Spacer()
        }
    }
}

struct MenuRow: View {
    let icon: String
    let title: String
    let showBadge: Bool
    var badgeColor: Color = .red
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if showBadge {
                    Circle()
                        .fill(badgeColor)
                        .frame(width: 8, height: 8)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var username = ""
    @State private var phone = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        
                        Button {
                            showingImagePicker = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 100, height: 100)
                                
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    VStack {
                                        Image(systemName: "camera.fill")
                                        Text("Add Photo")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                Section("Profile Information") {
                    TextField("Username", text: $username)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Account Information") {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(authManager.currentUser?.email ?? "")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Region")
                        Spacer()
                        Text(authManager.currentUser?.region ?? "")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Member Since")
                        Spacer()
                        Text(authManager.currentUser?.createdAt ?? Date(), formatter: DateFormatter.monthYear)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save profile changes
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImages: .constant([]))
            }
            .onAppear {
                username = authManager.currentUser?.username ?? ""
                phone = authManager.currentUser?.phone ?? ""
            }
        }
    }
}

struct UserStats {
    let totalMatches: Int
    let wins: Int
    let losses: Int
    let winRate: Double
    let totalEarnings: Int
    let biggestWin: Int
    let currentStreak: Int
    let favoriteActivity: String
}

class ProfileViewModel: ObservableObject {
    @Published var userStats: UserStats?
    @Published var isLoading = false
    
    func loadUserStats() async {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate loading user stats
        await MainActor.run {
            self.userStats = UserStats(
                totalMatches: 42,
                wins: 28,
                losses: 14,
                winRate: 0.67,
                totalEarnings: 5250,
                biggestWin: 850,
                currentStreak: 3,
                favoriteActivity: "Chess"
            )
        }
    }
}