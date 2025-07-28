import Foundation
@testable import BetApp

// MARK: - Mock Data Generator

class MockDataGenerator {
    
    // MARK: - Users
    
    static func createUser(
        id: UUID = UUID(),
        email: String = "test@example.com",
        username: String = "testuser",
        totalBalance: Int = 1000,
        withdrawableBalance: Int = 800,
        subscriptionStatus: User.SubscriptionStatus = .free,
        region: String = "United States",
        ageVerified: Bool = true
    ) -> User {
        return User(
            id: id,
            email: email,
            phone: nil,
            username: username,
            totalBalance: totalBalance,
            withdrawableBalance: withdrawableBalance,
            subscriptionStatus: subscriptionStatus,
            subscriptionExpiresAt: subscriptionStatus == .premium ? Date().addingTimeInterval(30 * 24 * 60 * 60) : nil,
            premiumTrialUses: [:],
            region: region,
            ageVerified: ageVerified,
            createdAt: Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
        )
    }
    
    static func createTestUsers() -> [User] {
        return [
            createUser(username: "test_free", subscriptionStatus: .free),
            createUser(username: "test_premium", subscriptionStatus: .premium, totalBalance: 5000, withdrawableBalance: 4500),
            createUser(username: "test_rich", totalBalance: 10000, withdrawableBalance: 9000),
            createUser(username: "test_poor", totalBalance: 100, withdrawableBalance: 50),
            createUser(username: "test_new", totalBalance: 500, withdrawableBalance: 500)
        ]
    }
    
    // MARK: - Matches
    
    static func createMatch(
        id: UUID = UUID(),
        creatorId: UUID = UUID(),
        activityType: String = "Test Activity",
        stakeAmount: Int = 100,
        status: Match.MatchStatus = .pending,
        isPremiumOnly: Bool = false,
        participantCount: Int = 1
    ) -> Match {
        var match = Match(
            id: id,
            creatorId: creatorId,
            activityType: activityType,
            activityTemplateId: nil,
            customRules: "Test rules for \(activityType)",
            stakeAmount: stakeAmount,
            totalPot: stakeAmount * participantCount,
            status: status,
            isPremiumOnly: isPremiumOnly,
            disputeProofUrl: nil,
            disputeDeadline: nil,
            createdAt: Date().addingTimeInterval(-60 * 60) // 1 hour ago
        )
        
        // Add participants
        var participants: [MatchParticipant] = []
        for i in 0..<participantCount {
            participants.append(createMatchParticipant(
                matchId: id,
                userId: i == 0 ? creatorId : UUID(),
                stakeAmount: stakeAmount
            ))
        }
        match.participants = participants
        
        return match
    }
    
    static func createMatchParticipant(
        id: UUID = UUID(),
        matchId: UUID = UUID(),
        userId: UUID = UUID(),
        stakeAmount: Int = 100,
        isWinner: Bool = false,
        hasVoted: Bool = false
    ) -> MatchParticipant {
        return MatchParticipant(
            id: id,
            matchId: matchId,
            userId: userId,
            stakeAmount: stakeAmount,
            isWinner: isWinner,
            leaveRequested: false,
            leaveApprovedBy: [],
            joinedAt: Date().addingTimeInterval(-30 * 60) // 30 minutes ago
        )
    }
    
    static func createTestMatches() -> [Match] {
        return [
            createMatch(activityType: "Chess", status: .active, participantCount: 2),
            createMatch(activityType: "Poker", status: .voting, participantCount: 3),
            createMatch(activityType: "Basketball", status: .pending, participantCount: 1),
            createMatch(activityType: "Premium Chess", status: .active, isPremiumOnly: true, participantCount: 2),
            createMatch(activityType: "Completed Game", status: .completed, participantCount: 4)
        ]
    }
    
    // MARK: - Activities
    
    static func createActivity(
        id: UUID = UUID(),
        name: String = "Test Activity",
        category: String = "Test Category",
        isPremium: Bool = false,
        suggestedStakes: [Int] = [50, 100, 200]
    ) -> ActivityTemplate {
        return ActivityTemplate(
            id: id,
            name: name,
            category: category,
            isPremium: isPremium,
            defaultRules: "Default rules for \(name)",
            iconName: "star.fill",
            suggestedStakes: suggestedStakes
        )
    }
    
    static func createTestActivities() -> [ActivityTemplate] {
        return [
            createActivity(name: "Chess", category: "Board Games", isPremium: false),
            createActivity(name: "Poker", category: "Card Games", isPremium: false),
            createActivity(name: "Basketball 1v1", category: "Sports", isPremium: false),
            createActivity(name: "FIFA Match", category: "Esports", isPremium: false),
            createActivity(name: "High Stakes Chess", category: "Premium", isPremium: true, suggestedStakes: [500, 1000, 2000]),
            createActivity(name: "Tournament Poker", category: "Premium", isPremium: true, suggestedStakes: [1000, 2500, 5000])
        ]
    }
    
    // MARK: - Transactions
    
    static func createTransaction(
        id: UUID = UUID(),
        userId: UUID = UUID(),
        amount: Int = 100,
        type: Transaction.TransactionType = .deposit,
        relatedMatchId: UUID? = nil
    ) -> Transaction {
        return Transaction(
            id: id,
            userId: userId,
            amount: amount,
            type: type,
            subtype: nil,
            relatedMatchId: relatedMatchId,
            stripePaymentIntentId: type == .deposit ? "pi_test_\(id.uuidString.prefix(8))" : nil,
            bonusAmount: type == .deposit ? Int(Double(amount) * 0.1) : 0,
            createdAt: Date().addingTimeInterval(-24 * 60 * 60) // 1 day ago
        )
    }
    
    static func createTestTransactions(for userId: UUID) -> [Transaction] {
        return [
            createTransaction(userId: userId, amount: 500, type: .deposit),
            createTransaction(userId: userId, amount: -100, type: .matchStake, relatedMatchId: UUID()),
            createTransaction(userId: userId, amount: 200, type: .matchPayout, relatedMatchId: UUID()),
            createTransaction(userId: userId, amount: -50, type: .matchStake, relatedMatchId: UUID()),
            createTransaction(userId: userId, amount: 1000, type: .deposit),
            createTransaction(userId: userId, amount: -300, type: .withdrawal)
        ]
    }
    
    // MARK: - Friendships
    
    static func createFriendship(
        id: UUID = UUID(),
        requesterId: UUID = UUID(),
        recipientId: UUID = UUID(),
        status: Friendship.FriendshipStatus = .pending
    ) -> Friendship {
        return Friendship(
            id: id,
            requesterId: requesterId,
            recipientId: recipientId,
            status: status,
            createdAt: Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
        )
    }
}

// MARK: - Mock Services

class MockStripeManager: StripeManager {
    var shouldSucceed = true
    var processingDelay: TimeInterval = 0.5
    
    override func processPayment(amount: Double) async throws -> Bool {
        try await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
        
        if shouldSucceed {
            return true
        } else {
            throw NSError(domain: "StripeError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Payment failed"])
        }
    }
    
    override func processWithdrawal(amount: Double) async throws -> Bool {
        try await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
        
        if shouldSucceed {
            return true
        } else {
            throw NSError(domain: "StripeError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Withdrawal failed"])
        }
    }
}

class MockNotificationManager: NotificationManager {
    var sentNotifications: [(title: String, body: String)] = []
    
    override func sendMatchInvite(from username: String, matchType: String) {
        sentNotifications.append((
            title: "Match Invite",
            body: "\(username) invited you to a \(matchType) match!"
        ))
    }
    
    override func sendVoteReminder(matchType: String) {
        sentNotifications.append((
            title: "Time to Vote!",
            body: "The \(matchType) match has ended. Vote for the winner now!"
        ))
    }
    
    override func sendPayoutNotification(amount: Int) {
        sentNotifications.append((
            title: "You Won! 🎉",
            body: "Congratulations! \(amount) tokens have been added to your wallet."
        ))
    }
}

class MockComplianceManager: ComplianceManager {
    var mockRestrictions: [String: String] = [:]
    var shouldAllowDeposit = true
    var shouldAllowWithdrawal = true
    var shouldRequireKYC = false
    
    override func checkDepositCompliance(amount: Int, region: String) async throws -> ComplianceStatus {
        if let restriction = mockRestrictions[region] {
            return ComplianceStatus(isAllowed: false, reason: restriction)
        }
        
        if !shouldAllowDeposit {
            return ComplianceStatus(isAllowed: false, reason: "Deposits not allowed in test mode")
        }
        
        return ComplianceStatus(isAllowed: true, reason: nil)
    }
    
    override func checkWithdrawalCompliance(amount: Int) async throws -> ComplianceStatus {
        if !shouldAllowWithdrawal {
            return ComplianceStatus(isAllowed: false, reason: "Withdrawals not allowed in test mode")
        }
        
        if shouldRequireKYC {
            return ComplianceStatus(isAllowed: false, reason: "KYC verification required")
        }
        
        return ComplianceStatus(isAllowed: true, reason: nil)
    }
}