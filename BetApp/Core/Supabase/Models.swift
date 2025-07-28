import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let phone: String?
    let username: String
    var totalBalance: Int
    var withdrawableBalance: Int
    var subscriptionStatus: SubscriptionStatus
    var subscriptionExpiresAt: Date?
    var premiumTrialUses: [String: Int]
    let region: String
    let ageVerified: Bool
    let createdAt: Date
    
    enum SubscriptionStatus: String, Codable {
        case free = "free"
        case premium = "premium"
        case premiumTrial = "premium_trial"
    }
    
    var isPremium: Bool {
        subscriptionStatus == .premium || subscriptionStatus == .premiumTrial
    }
    
    enum CodingKeys: String, CodingKey {
        case id, email, phone, username, region
        case totalBalance = "total_balance"
        case withdrawableBalance = "withdrawable_balance"
        case subscriptionStatus = "subscription_status"
        case subscriptionExpiresAt = "subscription_expires_at"
        case premiumTrialUses = "premium_trial_uses"
        case ageVerified = "age_verified"
        case createdAt = "created_at"
    }
}

struct Match: Codable, Identifiable {
    let id: UUID
    let creatorId: UUID
    let activityType: String
    let activityTemplateId: UUID?
    let customRules: String?
    let stakeAmount: Int
    var totalPot: Int
    var status: MatchStatus
    let isPremiumOnly: Bool
    var disputeProofUrl: [String]?
    var disputeDeadline: Date?
    let createdAt: Date
    
    var participants: [MatchParticipant]?
    var activity: ActivityTemplate?
    
    enum MatchStatus: String, Codable {
        case pending = "pending"
        case active = "active"
        case voting = "voting"
        case disputed = "disputed"
        case completed = "completed"
        case cancelled = "cancelled"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, status, participants, activity
        case creatorId = "creator_id"
        case activityType = "activity_type"
        case activityTemplateId = "activity_template_id"
        case customRules = "custom_rules"
        case stakeAmount = "stake_amount"
        case totalPot = "total_pot"
        case isPremiumOnly = "is_premium_only"
        case disputeProofUrl = "dispute_proof_url"
        case disputeDeadline = "dispute_deadline"
        case createdAt = "created_at"
    }
}

struct MatchParticipant: Codable, Identifiable {
    let id: UUID
    let matchId: UUID
    let userId: UUID
    let stakeAmount: Int
    var isWinner: Bool
    var leaveRequested: Bool
    var leaveApprovedBy: [UUID]
    let joinedAt: Date
    
    var user: User?
    
    enum CodingKeys: String, CodingKey {
        case id, user
        case matchId = "match_id"
        case userId = "user_id"
        case stakeAmount = "stake_amount"
        case isWinner = "is_winner"
        case leaveRequested = "leave_requested"
        case leaveApprovedBy = "leave_approved_by"
        case joinedAt = "joined_at"
    }
}

struct Friendship: Codable, Identifiable {
    let id: UUID
    let requesterId: UUID
    let recipientId: UUID
    var status: FriendshipStatus
    let createdAt: Date
    
    var requester: User?
    var recipient: User?
    
    enum FriendshipStatus: String, Codable {
        case pending = "pending"
        case accepted = "accepted"
        case declined = "declined"
        case blocked = "blocked"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, status, requester, recipient
        case requesterId = "requester_id"
        case recipientId = "recipient_id"
        case createdAt = "created_at"
    }
}

struct ActivityTemplate: Codable, Identifiable {
    let id: UUID
    let name: String
    let category: String
    let isPremium: Bool
    let defaultRules: String?
    let iconName: String?
    let suggestedStakes: [Int]
    
    enum CodingKeys: String, CodingKey {
        case id, name, category
        case isPremium = "is_premium"
        case defaultRules = "default_rules"
        case iconName = "icon_name"
        case suggestedStakes = "suggested_stakes"
    }
}

struct Transaction: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let amount: Int
    let type: TransactionType
    let subtype: String?
    let relatedMatchId: UUID?
    let stripePaymentIntentId: String?
    let bonusAmount: Int
    let createdAt: Date
    
    enum TransactionType: String, Codable {
        case deposit = "deposit"
        case withdrawal = "withdrawal"
        case matchStake = "match_stake"
        case matchPayout = "match_payout"
        case matchRefund = "match_refund"
        case bonus = "bonus"
        case fee = "fee"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, type, subtype
        case userId = "user_id"
        case amount
        case relatedMatchId = "related_match_id"
        case stripePaymentIntentId = "stripe_payment_intent_id"
        case bonusAmount = "bonus_amount"
        case createdAt = "created_at"
    }
}

struct ComplianceSettings: Codable {
    let region: String
    let isAllowed: Bool
    let ageRequirement: Int
    let maxDailyDeposit: Int?
    let maxSingleStake: Int?
    let requiresKYC: Bool
    
    enum CodingKeys: String, CodingKey {
        case region
        case isAllowed = "is_allowed"
        case ageRequirement = "age_requirement"
        case maxDailyDeposit = "max_daily_deposit"
        case maxSingleStake = "max_single_stake"
        case requiresKYC = "requires_kyc"
    }
}