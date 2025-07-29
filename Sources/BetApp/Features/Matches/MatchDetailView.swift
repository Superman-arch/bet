import SwiftUI
#if os(iOS)
import UIKit
#endif

struct MatchDetailView: View {
    let match: Match
    @StateObject private var viewModel = MatchDetailViewModel()
    @EnvironmentObject var walletManager: WalletManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var showingVoteSheet = false
    @State private var showingDisputeSheet = false
    @State private var showingLeaveConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Match Header
                    MatchHeaderView(match: match)
                    
                    // Status Banner
                    StatusBanner(status: match.status)
                    
                    // Participants
                    ParticipantsSection(
                        participants: viewModel.participants,
                        currentUserId: authManager.currentUser?.id
                    )
                    
                    // Rules Section
                    RulesSection(rules: match.customRules ?? match.activity?.defaultRules ?? "No rules specified")
                    
                    // Prize Pool
                    PrizePoolSection(totalPot: match.totalPot, isPremium: match.isPremiumOnly)
                    
                    // Action Buttons
                    ActionButtonsSection(
                        match: match,
                        viewModel: viewModel,
                        showingVoteSheet: $showingVoteSheet,
                        showingDisputeSheet: $showingDisputeSheet,
                        showingLeaveConfirmation: $showingLeaveConfirmation
                    )
                    
                    // Activity Feed
                    if !viewModel.activityFeed.isEmpty {
                        ActivityFeedSection(activities: viewModel.activityFeed)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Match Details")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .trailingBar) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingVoteSheet) {
                VoteSheet(match: match, viewModel: viewModel)
            }
            .sheet(isPresented: $showingDisputeSheet) {
                DisputeSheet(match: match, viewModel: viewModel)
            }
            .alert("Leave Match?", isPresented: $showingLeaveConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Leave", role: .destructive) {
                    Task {
                        await viewModel.requestLeave()
                    }
                }
            } message: {
                Text("You need approval from all participants to leave and get your stake back.")
            }
            .task {
                await viewModel.loadMatch(match)
            }
        }
    }
}

struct MatchHeaderView: View {
    let match: Match
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: match.activity?.iconName ?? "gamecontroller.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text(match.activityType)
                .font(.title)
                .fontWeight(.bold)
            
            if match.isPremiumOnly {
                Label("Premium Match", systemImage: "crown.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(15)
            }
        }
        .padding()
    }
}

struct StatusBanner: View {
    let status: Match.MatchStatus
    
    var message: String {
        switch status {
        case .pending:
            return "Waiting for players to join..."
        case .active:
            return "Match is in progress!"
        case .voting:
            return "Time to vote for the winner"
        case .disputed:
            return "Match is under dispute review"
        case .completed:
            return "Match completed"
        case .cancelled:
            return "Match was cancelled"
        }
    }
    
    var color: Color {
        switch status {
        case .pending: return .orange
        case .active: return .blue
        case .voting: return .purple
        case .disputed: return .red
        case .completed: return .green
        case .cancelled: return .gray
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "info.circle.fill")
            Text(message)
                .fontWeight(.medium)
            Spacer()
        }
        .foregroundColor(.white)
        .padding()
        .background(color)
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct ParticipantsSection: View {
    let participants: [MatchParticipant]
    let currentUserId: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Participants")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(participants) { participant in
                ParticipantRow(
                    participant: participant,
                    isCurrentUser: participant.userId == currentUserId
                )
                .padding(.horizontal)
            }
        }
    }
}

struct ParticipantRow: View {
    let participant: MatchParticipant
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(participant.user?.username.prefix(2).uppercased() ?? "??")
                        .fontWeight(.bold)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(participant.user?.username ?? "Unknown")
                        .fontWeight(.medium)
                    
                    if isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if participant.isWinner {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                
                Text("Stake: \(participant.stakeAmount) tokens")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if participant.leaveRequested {
                Text("Leave Requested")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(5)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isCurrentUser ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
        )
    }
}

struct RulesSection: View {
    let rules: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Rules")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                Text(rules)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }
}

struct PrizePoolSection: View {
    let totalPot: Int
    let isPremium: Bool
    
    var afterFees: Int {
        isPremium ? totalPot : Int(Double(totalPot) * 0.98)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Prize Pool")
                .font(.headline)
            
            VStack(spacing: 5) {
                Text("\(totalPot) tokens")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                
                if !isPremium {
                    Text("\(afterFees) after fees")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.green.opacity(0.1))
        )
        .padding(.horizontal)
    }
}

struct ActionButtonsSection: View {
    let match: Match
    let viewModel: MatchDetailViewModel
    @Binding var showingVoteSheet: Bool
    @Binding var showingDisputeSheet: Bool
    @Binding var showingLeaveConfirmation: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            if match.status == .pending && !viewModel.isParticipant {
                Button {
                    Task {
                        await viewModel.joinMatch()
                    }
                } label: {
                    Label("Join Match", systemImage: "plus.circle.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(viewModel.isProcessing)
            }
            
            if match.status == .voting && viewModel.isParticipant && !viewModel.hasVoted {
                Button {
                    showingVoteSheet = true
                } label: {
                    Label("Vote for Winner", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            
            if match.status == .disputed && viewModel.isParticipant {
                Button {
                    showingDisputeSheet = true
                } label: {
                    Label("Submit Evidence", systemImage: "camera.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            
            if (match.status == .pending || match.status == .active) && viewModel.isParticipant {
                Button {
                    showingLeaveConfirmation = true
                } label: {
                    Label("Request to Leave", systemImage: "arrow.left.circle")
                        .foregroundColor(.red)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(.horizontal)
    }
}

struct ActivityFeedSection: View {
    let activities: [MatchActivity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Activity")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(activities) { activity in
                HStack {
                    Image(systemName: activity.icon)
                        .foregroundColor(.secondary)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activity.message)
                            .font(.subheadline)
                        
                        Text(activity.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
    }
}

struct VoteSheet: View {
    let match: Match
    let viewModel: MatchDetailViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedWinner: UUID?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Select the Winner")
                    .font(.headline)
                    .padding(.top)
                
                ForEach(viewModel.participants) { participant in
                    Button {
                        selectedWinner = participant.userId
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(participant.user?.username.prefix(2).uppercased() ?? "??")
                                        .fontWeight(.bold)
                                )
                            
                            Text(participant.user?.username ?? "Unknown")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedWinner == participant.userId {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedWinner == participant.userId ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
                        )
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                Button {
                    Task {
                        if let winnerId = selectedWinner {
                            await viewModel.submitVote(winnerId: winnerId)
                            dismiss()
                        }
                    }
                } label: {
                    Text("Submit Vote")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(selectedWinner == nil || viewModel.isProcessing)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("Vote for Winner")
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

struct DisputeSheet: View {
    let match: Match
    let viewModel: MatchDetailViewModel
    @Environment(\.dismiss) var dismiss
    #if os(iOS)
    @State private var selectedImages: [UIImage] = []
    #else
    @State private var selectedImages: [Any] = []
    #endif
    @State private var showingImagePicker = false
    @State private var disputeReason = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Submit Evidence")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("Upload proof to support your dispute claim")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Image picker button
                    Button {
                        showingImagePicker = true
                    } label: {
                        VStack {
                            Image(systemName: "camera.fill")
                                .font(.largeTitle)
                            Text("Add Photos")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // Selected images
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                #if os(iOS)
                                ForEach(Array((selectedImages as? [UIImage] ?? []).enumerated()), id: \.offset) { index, image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                        .cornerRadius(10)
                                }
                                #else
                                ForEach(0..<selectedImages.count, id: \.self) { index in
                                    Rectangle()
                                        .fill(Color.gray)
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(10)
                                }
                                #endif
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Dispute reason
                    VStack(alignment: .leading) {
                        Text("Reason for Dispute")
                            .font(.headline)
                        
                        TextEditor(text: $disputeReason)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Dispute Match")
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
                    Button("Submit") {
                        Task {
                            await viewModel.submitDispute(images: selectedImages, reason: disputeReason)
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedImages.isEmpty || viewModel.isProcessing)
                }
            }
            #if os(iOS)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImages: $selectedImages)
            }
            #endif
        }
    }
}

struct MatchActivity: Identifiable {
    let id = UUID()
    let icon: String
    let message: String
    let timestamp: Date
}

class MatchDetailViewModel: ObservableObject {
    @Published var match: Match?
    @Published var participants: [MatchParticipant] = []
    @Published var activityFeed: [MatchActivity] = []
    @Published var isProcessing = false
    @Published var error: String?
    
    var isParticipant: Bool {
        guard let currentUserId = SupabaseManager.shared.currentUser?.id else { return false }
        return participants.contains { $0.userId == currentUserId }
    }
    
    var hasVoted: Bool {
        // Check if current user has voted
        return false // Implement vote checking
    }
    
    func loadMatch(_ match: Match) async {
        self.match = match
        self.participants = match.participants ?? []
        
        // Load activity feed
        await loadActivityFeed()
    }
    
    func joinMatch() async {
        guard let match = match else { return }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            try await SupabaseManager.shared.joinMatch(matchId: match.id, stakeAmount: match.stakeAmount)
            
            // Refresh match data
            await loadMatch(match)
            
            HapticManager.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.error()
        }
    }
    
    func submitVote(winnerId: UUID) async {
        guard let match = match else { return }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            try await SupabaseManager.shared.voteForWinner(matchId: match.id, winnerId: winnerId)
            HapticManager.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.error()
        }
    }
    
    func submitDispute(images: [Any], reason: String) async {
        // Upload images and submit dispute
        isProcessing = true
        defer { isProcessing = false }
        
        // Implementation for uploading images and creating dispute
        HapticManager.success()
    }
    
    func requestLeave() async {
        // Request to leave match
        isProcessing = true
        defer { isProcessing = false }
        
        // Implementation for leave request
        HapticManager.success()
    }
    
    private func loadActivityFeed() async {
        // Simulate loading activity feed
        activityFeed = [
            MatchActivity(icon: "person.badge.plus", message: "John joined the match", timestamp: Date().addingTimeInterval(-3600)),
            MatchActivity(icon: "play.circle", message: "Match started", timestamp: Date().addingTimeInterval(-1800)),
            MatchActivity(icon: "checkmark.circle", message: "Voting phase began", timestamp: Date().addingTimeInterval(-600))
        ]
    }
}

#if os(iOS)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImages.append(image)
            }
            picker.dismiss(animated: true)
        }
    }
}
#endif