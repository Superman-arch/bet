import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("biometricEnabled") private var biometricEnabled = false
    @AppStorage("autoPlaySounds") private var autoPlaySounds = true
    @AppStorage("showOnlineStatus") private var showOnlineStatus = true
    @State private var selectedAppearance = AppearanceMode.system
    @State private var showingDeleteAccount = false
    @State private var showingPrivacy = false
    @State private var showingTerms = false
    
    enum AppearanceMode: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Appearance Section
                Section("Appearance") {
                    Picker("Theme", selection: $selectedAppearance) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                }
                
                // Notifications Section
                Section("Notifications") {
                    Toggle("Push Notifications", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        NavigationLink("Notification Preferences") {
                            NotificationPreferencesView()
                        }
                    }
                }
                
                // Privacy & Security Section
                Section("Privacy & Security") {
                    Toggle("Face ID / Touch ID", isOn: $biometricEnabled)
                    
                    Toggle("Show Online Status", isOn: $showOnlineStatus)
                    
                    NavigationLink("Blocked Users") {
                        BlockedUsersView()
                    }
                    
                    NavigationLink("Data & Privacy") {
                        DataPrivacyView()
                    }
                }
                
                // Game Settings Section
                Section("Game Settings") {
                    Toggle("Sound Effects", isOn: $autoPlaySounds)
                    
                    NavigationLink("Match Defaults") {
                        MatchDefaultsView()
                    }
                }
                
                // Legal Section
                Section("Legal") {
                    Button("Terms of Service") {
                        showingTerms = true
                    }
                    
                    Button("Privacy Policy") {
                        showingPrivacy = true
                    }
                    
                    NavigationLink("Licenses") {
                        LicensesView()
                    }
                }
                
                // Account Section
                Section("Account") {
                    NavigationLink("Export Data") {
                        ExportDataView()
                    }
                    
                    Button("Delete Account", role: .destructive) {
                        showingDeleteAccount = true
                    }
                }
                
                // App Info Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Rate Bet App") {
                        // Open App Store
                    }
                    
                    Button("Share Bet App") {
                        // Share sheet
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Account?", isPresented: $showingDeleteAccount) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    // Delete account
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
            .sheet(isPresented: $showingPrivacy) {
                SafariView(url: URL(string: "https://betapp.com/privacy")!)
            }
            .sheet(isPresented: $showingTerms) {
                SafariView(url: URL(string: "https://betapp.com/terms")!)
            }
        }
    }
}

struct NotificationPreferencesView: View {
    @AppStorage("matchInvites") private var matchInvites = true
    @AppStorage("voteReminders") private var voteReminders = true
    @AppStorage("friendRequests") private var friendRequests = true
    @AppStorage("promotions") private var promotions = false
    @AppStorage("weeklyReports") private var weeklyReports = true
    
    var body: some View {
        Form {
            Section("Match Notifications") {
                Toggle("Match Invites", isOn: $matchInvites)
                Toggle("Vote Reminders", isOn: $voteReminders)
                Toggle("Match Results", isOn: .constant(true))
            }
            
            Section("Social Notifications") {
                Toggle("Friend Requests", isOn: $friendRequests)
                Toggle("Friend Activity", isOn: .constant(false))
            }
            
            Section("Other") {
                Toggle("Promotions & Offers", isOn: $promotions)
                Toggle("Weekly Activity Reports", isOn: $weeklyReports)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BlockedUsersView: View {
    @State private var blockedUsers: [User] = []
    
    var body: some View {
        List {
            if blockedUsers.isEmpty {
                ContentUnavailableView(
                    "No Blocked Users",
                    systemImage: "person.slash",
                    description: Text("Users you block will appear here")
                )
            } else {
                ForEach(blockedUsers) { user in
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(user.username.prefix(2).uppercased())
                                    .font(.caption)
                                    .fontWeight(.bold)
                            )
                        
                        Text(user.username)
                        
                        Spacer()
                        
                        Button("Unblock") {
                            // Unblock user
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataPrivacyView: View {
    @State private var dataUsageStats: DataUsageStats?
    
    var body: some View {
        List {
            Section("Data Collection") {
                PrivacyRow(
                    title: "Match Data",
                    description: "Your match history and statistics",
                    isEnabled: true
                )
                
                PrivacyRow(
                    title: "Analytics",
                    description: "App usage and performance data",
                    isEnabled: false
                )
                
                PrivacyRow(
                    title: "Crash Reports",
                    description: "Technical data when issues occur",
                    isEnabled: true
                )
            }
            
            Section("Data Usage") {
                if let stats = dataUsageStats {
                    HStack {
                        Text("Total Data Stored")
                        Spacer()
                        Text(stats.formattedSize)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Last Backup")
                        Spacer()
                        Text(stats.lastBackup, style: .relative)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section {
                Button("Download My Data") {
                    // Initiate data export
                }
                
                Button("Request Data Deletion", role: .destructive) {
                    // Request deletion
                }
            }
        }
        .navigationTitle("Data & Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyRow: View {
    let title: String
    let description: String
    let isEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundColor(isEnabled ? .green : .secondary)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct MatchDefaultsView: View {
    @AppStorage("defaultStakeAmount") private var defaultStakeAmount = 100
    @AppStorage("defaultMatchPrivacy") private var defaultMatchPrivacy = "friends"
    @AppStorage("autoAcceptFriends") private var autoAcceptFriends = false
    
    var body: some View {
        Form {
            Section("Default Settings") {
                Stepper("Default Stake: \(defaultStakeAmount) tokens", value: $defaultStakeAmount, in: 50...1000, step: 50)
                
                Picker("Default Privacy", selection: $defaultMatchPrivacy) {
                    Text("Friends Only").tag("friends")
                    Text("Public").tag("public")
                    Text("Private").tag("private")
                }
                
                Toggle("Auto-accept friend match invites", isOn: $autoAcceptFriends)
            }
            
            Section {
                Text("These settings will be used as defaults when creating new matches. You can always change them for individual matches.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Match Defaults")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExportDataView: View {
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            VStack(spacing: 10) {
                Text("Export Your Data")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Download all your Bet app data including matches, transactions, and profile information.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            if isExporting {
                VStack(spacing: 15) {
                    ProgressView(value: exportProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text("Preparing your data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 40)
            } else {
                Button {
                    startExport()
                } label: {
                    Label("Start Export", systemImage: "arrow.down.doc")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding(.top, 60)
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func startExport() {
        isExporting = true
        
        // Simulate export progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            exportProgress += 0.05
            if exportProgress >= 1.0 {
                timer.invalidate()
                completeExport()
            }
        }
    }
    
    private func completeExport() {
        // Complete export and share file
        isExporting = false
        exportProgress = 0
    }
}

struct LicensesView: View {
    var body: some View {
        List {
            LicenseRow(name: "SwiftUI", license: "MIT License")
            LicenseRow(name: "Supabase", license: "Apache 2.0")
            LicenseRow(name: "Stripe iOS SDK", license: "MIT License")
        }
        .navigationTitle("Licenses")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LicenseRow: View {
    let name: String
    let license: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .fontWeight(.medium)
            Text(license)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct DataUsageStats {
    let totalSize: Int64
    let lastBackup: Date
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        return formatter.string(fromByteCount: totalSize)
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

import SafariServices

struct ContentUnavailableView: View {
    let title: String
    let systemImage: String
    let description: Text
    
    init(_ title: String, systemImage: String, description: Text) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 10) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                description
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}