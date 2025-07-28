import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    @Published var hasPermission = false
    @Published var pendingNotifications: [BetNotification] = []
    
    private let center = UNUserNotificationCenter.current()
    
    init() {
        checkPermission()
    }
    
    func requestAuthorization() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.hasPermission = granted
            }
            
            if granted {
                await registerForPushNotifications()
            }
        } catch {
            print("Error requesting notification permission: \(error)")
        }
    }
    
    private func checkPermission() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func registerForPushNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - Notification Types
    
    func sendMatchInvite(from username: String, matchType: String) {
        let content = UNMutableNotificationContent()
        content.title = "Match Invite"
        content.body = "\(username) invited you to a \(matchType) match!"
        content.sound = .default
        content.categoryIdentifier = "MATCH_INVITE"
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        center.add(request)
    }
    
    func sendVoteReminder(matchType: String) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Vote!"
        content.body = "The \(matchType) match has ended. Vote for the winner now!"
        content.sound = .default
        content.categoryIdentifier = "VOTE_REMINDER"
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        center.add(request)
    }
    
    func sendPayoutNotification(amount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "You Won! 🎉"
        content.body = "Congratulations! \(amount) tokens have been added to your wallet."
        content.sound = UNSoundName("win.mp3")
        content.categoryIdentifier = "PAYOUT"
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        center.add(request)
    }
    
    func sendDisputeUpdate(matchType: String, status: String) {
        let content = UNMutableNotificationContent()
        content.title = "Dispute Update"
        content.body = "Your \(matchType) match dispute has been \(status)"
        content.sound = .default
        content.categoryIdentifier = "DISPUTE_UPDATE"
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        center.add(request)
    }
    
    func sendFriendRequest(from username: String) {
        let content = UNMutableNotificationContent()
        content.title = "Friend Request"
        content.body = "\(username) wants to be your friend"
        content.sound = .default
        content.categoryIdentifier = "FRIEND_REQUEST"
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        center.add(request)
    }
    
    // MARK: - Notification Categories
    
    func setupNotificationCategories() {
        let acceptAction = UNNotificationAction(
            identifier: "ACCEPT",
            title: "Accept",
            options: .foreground
        )
        
        let declineAction = UNNotificationAction(
            identifier: "DECLINE",
            title: "Decline",
            options: .destructive
        )
        
        let viewAction = UNNotificationAction(
            identifier: "VIEW",
            title: "View",
            options: .foreground
        )
        
        let matchInviteCategory = UNNotificationCategory(
            identifier: "MATCH_INVITE",
            actions: [acceptAction, declineAction],
            intentIdentifiers: []
        )
        
        let voteReminderCategory = UNNotificationCategory(
            identifier: "VOTE_REMINDER",
            actions: [viewAction],
            intentIdentifiers: []
        )
        
        let friendRequestCategory = UNNotificationCategory(
            identifier: "FRIEND_REQUEST",
            actions: [acceptAction, declineAction],
            intentIdentifiers: []
        )
        
        center.setNotificationCategories([
            matchInviteCategory,
            voteReminderCategory,
            friendRequestCategory
        ])
    }
    
    // MARK: - Badge Management
    
    func updateBadgeCount(_ count: Int) {
        Task { @MainActor in
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
    
    func clearBadge() {
        updateBadgeCount(0)
    }
}

struct BetNotification: Identifiable {
    let id = UUID()
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    let isRead: Bool
    let actionData: [String: Any]?
    
    enum NotificationType {
        case matchInvite
        case voteReminder
        case payout
        case dispute
        case friendRequest
        case promotion
        case system
    }
}

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.notifications) { notification in
                    NotificationRow(notification: notification) {
                        viewModel.handleNotificationTap(notification)
                    }
                }
                .onDelete { indexSet in
                    viewModel.deleteNotifications(at: indexSet)
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All") {
                        viewModel.clearAll()
                    }
                    .disabled(viewModel.notifications.isEmpty)
                }
            }
            .overlay {
                if viewModel.notifications.isEmpty {
                    EmptyStateView(
                        icon: "bell.slash",
                        title: "No Notifications",
                        message: "You're all caught up!"
                    )
                }
            }
        }
    }
}

struct NotificationRow: View {
    let notification: BetNotification
    let action: () -> Void
    
    var icon: String {
        switch notification.type {
        case .matchInvite: return "gamecontroller.fill"
        case .voteReminder: return "checkmark.circle.fill"
        case .payout: return "dollarsign.circle.fill"
        case .dispute: return "exclamationmark.triangle.fill"
        case .friendRequest: return "person.badge.plus"
        case .promotion: return "tag.fill"
        case .system: return "info.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch notification.type {
        case .matchInvite: return .blue
        case .voteReminder: return .purple
        case .payout: return .green
        case .dispute: return .red
        case .friendRequest: return .orange
        case .promotion: return .yellow
        case .system: return .gray
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(notification.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Text(notification.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !notification.isRead {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

class NotificationsViewModel: ObservableObject {
    @Published var notifications: [BetNotification] = []
    
    init() {
        loadNotifications()
    }
    
    private func loadNotifications() {
        // Load notifications from storage or API
        notifications = [
            BetNotification(
                type: .matchInvite,
                title: "Match Invite",
                message: "john_doe invited you to a Chess match",
                timestamp: Date().addingTimeInterval(-300),
                isRead: false,
                actionData: ["matchId": "123"]
            ),
            BetNotification(
                type: .payout,
                title: "You Won!",
                message: "500 tokens added to your wallet",
                timestamp: Date().addingTimeInterval(-3600),
                isRead: true,
                actionData: nil
            ),
            BetNotification(
                type: .voteReminder,
                title: "Time to Vote",
                message: "Basketball match ended - vote now",
                timestamp: Date().addingTimeInterval(-7200),
                isRead: false,
                actionData: ["matchId": "456"]
            )
        ]
    }
    
    func handleNotificationTap(_ notification: BetNotification) {
        // Mark as read
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index] = BetNotification(
                type: notification.type,
                title: notification.title,
                message: notification.message,
                timestamp: notification.timestamp,
                isRead: true,
                actionData: notification.actionData
            )
        }
        
        // Handle action based on type
        switch notification.type {
        case .matchInvite, .voteReminder:
            if let matchId = notification.actionData?["matchId"] as? String {
                // Navigate to match
            }
        case .friendRequest:
            // Navigate to social tab
            break
        default:
            break
        }
    }
    
    func deleteNotifications(at offsets: IndexSet) {
        notifications.remove(atOffsets: offsets)
    }
    
    func clearAll() {
        notifications.removeAll()
    }
}