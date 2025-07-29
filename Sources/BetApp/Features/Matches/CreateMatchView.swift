import SwiftUI

struct CreateMatchView: View {
    @StateObject private var viewModel = CreateMatchViewModel()
    @EnvironmentObject var walletManager: WalletManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    // Activity Selection
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Select Activity")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(ActivityCategory.allCases, id: \.self) { category in
                                    CategoryChip(
                                        category: category,
                                        isSelected: viewModel.selectedCategory == category
                                    ) {
                                        viewModel.selectedCategory = category
                                        viewModel.filterActivities()
                                    }
                                }
                            }
                        }
                        
                        if viewModel.filteredActivities.isEmpty {
                            Text("Loading activities...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(viewModel.filteredActivities) { activity in
                                ActivityRow(
                                    activity: activity,
                                    isSelected: viewModel.selectedActivity?.id == activity.id
                                ) {
                                    viewModel.selectActivity(activity)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    if viewModel.selectedActivity != nil {
                        VStack(spacing: 20) {
                            // Stake Selection
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Select Stake Amount")
                                    .font(.headline)
                                
                                if let suggestedStakes = viewModel.selectedActivity?.suggestedStakes {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 10) {
                                            ForEach(suggestedStakes, id: \.self) { stake in
                                                StakeChip(
                                                    amount: stake,
                                                    isSelected: viewModel.stakeAmount == stake
                                                ) {
                                                    viewModel.stakeAmount = stake
                                                }
                                            }
                                            
                                            Button {
                                                viewModel.showingCustomStake = true
                                            } label: {
                                                Text("Custom")
                                                    .padding(.horizontal, 20)
                                                    .padding(.vertical, 10)
                                                    .background(Color.gray.opacity(0.2))
                                                    .cornerRadius(20)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Rules
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Match Rules")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Button("Edit") {
                                        viewModel.showingRulesEditor = true
                                    }
                                    .font(.caption)
                                }
                                
                                Text(viewModel.matchRules.isEmpty ? viewModel.selectedActivity?.defaultRules ?? "No rules set" : viewModel.matchRules)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                            }
                            
                            // Match Settings
                            VStack(spacing: 15) {
                                Toggle("Premium Members Only", isOn: $viewModel.isPremiumOnly)
                                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                                
                                if viewModel.isPremiumOnly {
                                    Label("No processing fees for premium matches", systemImage: "info.circle")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Invite Friends
                    if viewModel.selectedActivity != nil {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Invite Friends")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("\(viewModel.invitedFriends.count) selected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button {
                                viewModel.showingFriendPicker = true
                            } label: {
                                Label("Select Friends", systemImage: "person.badge.plus")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Create Match")
            #if os(iOS)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            #endif
            .toolbar {
                ToolbarItem(placement: .leadingBar) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .trailingBar) {
                    Button("Create") {
                        Task {
                            await viewModel.createMatch(walletManager: walletManager)
                            if viewModel.matchCreated {
                                dismiss()
                            }
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.canCreateMatch || viewModel.isCreating)
                }
            }
            .sheet(isPresented: $viewModel.showingCustomStake) {
                CustomStakeView(stakeAmount: $viewModel.stakeAmount)
            }
            .sheet(isPresented: $viewModel.showingRulesEditor) {
                RulesEditorView(rules: $viewModel.matchRules)
            }
            .sheet(isPresented: $viewModel.showingFriendPicker) {
                FriendPickerView(selectedFriends: $viewModel.invitedFriends)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .task {
                await viewModel.loadActivities()
            }
        }
    }
}

struct CategoryChip: View {
    let category: ActivityCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct ActivityRow: View {
    let activity: ActivityTemplate
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: activity.iconName ?? "star.fill")
                    .font(.title2)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(activity.name)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        if activity.isPremium {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    if let rules = activity.defaultRules {
                        Text(rules)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
            )
        }
    }
}

struct StakeChip: View {
    let amount: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(amount) tokens")
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

enum ActivityCategory: String, CaseIterable {
    case sports = "Sports"
    case games = "Games"
    case esports = "Esports"
    case creative = "Creative"
    case premium = "Premium"
}

class CreateMatchViewModel: ObservableObject {
    @Published var selectedCategory: ActivityCategory?
    @Published var selectedActivity: ActivityTemplate?
    @Published var stakeAmount = 0
    @Published var matchRules = ""
    @Published var isPremiumOnly = false
    @Published var invitedFriends: [User] = []
    @Published var allActivities: [ActivityTemplate] = []
    @Published var showingCustomStake = false
    @Published var showingRulesEditor = false
    @Published var showingFriendPicker = false
    @Published var isCreating = false
    @Published var matchCreated = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    var filteredActivities: [ActivityTemplate] {
        guard let category = selectedCategory else { return allActivities }
        return allActivities.filter { $0.category == category.rawValue }
    }
    
    var canCreateMatch: Bool {
        selectedActivity != nil && stakeAmount > 0
    }
    
    func loadActivities() async {
        do {
            let activities = try await SupabaseManager.shared.fetchActivityTemplates()
            await MainActor.run {
                self.allActivities = activities
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    func filterActivities() {
        // Activities are filtered via computed property
    }
    
    func selectActivity(_ activity: ActivityTemplate) {
        selectedActivity = activity
        matchRules = activity.defaultRules ?? ""
        if let suggestedStake = activity.suggestedStakes.first {
            stakeAmount = suggestedStake
        }
        HapticManager.selection()
    }
    
    func createMatch(walletManager: WalletManager) async {
        guard let activity = selectedActivity else { return }
        
        isCreating = true
        defer { isCreating = false }
        
        // Check balance
        guard walletManager.canAffordStake(stakeAmount) else {
            errorMessage = "Insufficient balance. You need \(stakeAmount) tokens."
            showError = true
            HapticManager.error()
            return
        }
        
        do {
            let match = try await SupabaseManager.shared.createMatch(
                activityType: activity.name,
                activityTemplateId: activity.id,
                customRules: matchRules.isEmpty ? nil : matchRules,
                stakeAmount: stakeAmount,
                isPremiumOnly: isPremiumOnly
            )
            
            // Deduct stake from wallet
            try await walletManager.deductStake(stakeAmount, for: match.id)
            
            // Send invites to friends
            for _ in invitedFriends {
                // Send push notification or in-app invite
            }
            
            await MainActor.run {
                self.matchCreated = true
                HapticManager.success()
            }
            
            // Track analytics
            AnalyticsManager.shared.track(
                event: AppEnvironment.AnalyticsEvents.matchCreated,
                properties: [
                    "activity": activity.name,
                    "stake": stakeAmount,
                    "premium_only": isPremiumOnly,
                    "invited_count": invitedFriends.count
                ]
            )
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.error()
        }
    }
}

struct CustomStakeView: View {
    @Binding var stakeAmount: Int
    @State private var tempAmount = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Enter Custom Stake")
                    .font(.headline)
                    .padding(.top, 40)
                
                CustomTextField(
                    placeholder: "Amount",
                    text: $tempAmount,
                    icon: "dollarsign",
                    keyboardType: .numberPad
                )
                .padding(.horizontal, 40)
                
                Spacer()
                
                Button("Set Amount") {
                    if let amount = Int(tempAmount), amount > 0 {
                        stakeAmount = amount
                        dismiss()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(Int(tempAmount) == nil || Int(tempAmount) == 0)
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .trailingBar) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct RulesEditorView: View {
    @Binding var rules: String
    @Environment(\.dismiss) var dismiss
    @State private var tempRules = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $tempRules)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding()
            }
            .navigationTitle("Edit Rules")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .leadingBar) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .trailingBar) {
                    Button("Save") {
                        rules = tempRules
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                tempRules = rules
            }
        }
    }
}

struct FriendPickerView: View {
    @Binding var selectedFriends: [User]
    @Environment(\.dismiss) var dismiss
    @State private var friends: [User] = []
    @State private var searchText = ""
    
    var filteredFriends: [User] {
        if searchText.isEmpty {
            return friends
        }
        return friends.filter { $0.username.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredFriends) { friend in
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(friend.username.prefix(1).uppercased())
                                    .fontWeight(.bold)
                            )
                        
                        Text(friend.username)
                        
                        Spacer()
                        
                        if selectedFriends.contains(where: { $0.id == friend.id }) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleFriend(friend)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search friends")
            .navigationTitle("Invite Friends")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .trailingBar) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .task {
                await loadFriends()
            }
        }
    }
    
    private func toggleFriend(_ friend: User) {
        if let index = selectedFriends.firstIndex(where: { $0.id == friend.id }) {
            selectedFriends.remove(at: index)
        } else {
            selectedFriends.append(friend)
        }
        HapticManager.selection()
    }
    
    private func loadFriends() async {
        do {
            friends = try await SupabaseManager.shared.fetchFriends()
        } catch {
            print("Error loading friends: \(error)")
        }
    }
}