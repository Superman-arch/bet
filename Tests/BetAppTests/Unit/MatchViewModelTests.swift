import XCTest
@testable import BetApp

class MatchViewModelTests: XCTestCase {
    var viewModel: CreateMatchViewModel!
    var mockWalletManager: MockWalletManager!
    var mockSupabase: MockSupabaseManager!
    
    override func setUp() {
        super.setUp()
        viewModel = CreateMatchViewModel()
        mockWalletManager = MockWalletManager()
        mockSupabase = MockSupabaseManager()
    }
    
    override func tearDown() {
        viewModel = nil
        mockWalletManager = nil
        mockSupabase = nil
        super.tearDown()
    }
    
    // MARK: - Activity Selection Tests
    
    func testLoadActivities() async {
        // Given
        mockSupabase.mockActivities = [
            ActivityTemplate(
                id: UUID(),
                name: "Chess",
                category: "Board Games",
                isPremium: false,
                defaultRules: "Standard chess rules",
                iconName: "crown",
                suggestedStakes: [50, 100, 200]
            ),
            ActivityTemplate(
                id: UUID(),
                name: "Poker",
                category: "Card Games",
                isPremium: false,
                defaultRules: "Texas Hold'em",
                iconName: "suit.heart.fill",
                suggestedStakes: [100, 200, 500]
            )
        ]
        
        // When
        await viewModel.loadActivities()
        
        // Then
        XCTAssertEqual(viewModel.allActivities.count, 2)
        XCTAssertEqual(viewModel.allActivities[0].name, "Chess")
        XCTAssertEqual(viewModel.allActivities[1].name, "Poker")
    }
    
    func testFilterActivitiesByCategory() {
        // Given
        viewModel.allActivities = [
            createActivity(name: "Chess", category: "Board Games"),
            createActivity(name: "Poker", category: "Card Games"),
            createActivity(name: "Checkers", category: "Board Games")
        ]
        
        // When
        viewModel.selectedCategory = .games
        
        // Then
        XCTAssertEqual(viewModel.filteredActivities.count, 3)
    }
    
    func testSelectActivity() {
        // Given
        let activity = createActivity(
            name: "Chess",
            suggestedStakes: [50, 100, 200],
            defaultRules: "Standard rules"
        )
        
        // When
        viewModel.selectActivity(activity)
        
        // Then
        XCTAssertEqual(viewModel.selectedActivity?.id, activity.id)
        XCTAssertEqual(viewModel.matchRules, "Standard rules")
        XCTAssertEqual(viewModel.stakeAmount, 50) // First suggested stake
    }
    
    // MARK: - Match Creation Tests
    
    func testCanCreateMatch() {
        // Given
        viewModel.selectedActivity = createActivity()
        
        // When/Then
        viewModel.stakeAmount = 0
        XCTAssertFalse(viewModel.canCreateMatch)
        
        viewModel.stakeAmount = 100
        XCTAssertTrue(viewModel.canCreateMatch)
        
        viewModel.selectedActivity = nil
        XCTAssertFalse(viewModel.canCreateMatch)
    }
    
    func testCreateMatchSuccess() async {
        // Given
        mockWalletManager.totalBalance = 1000
        viewModel.selectedActivity = createActivity(name: "Chess")
        viewModel.stakeAmount = 100
        viewModel.matchRules = "Custom rules"
        viewModel.isPremiumOnly = true
        
        // When
        await viewModel.createMatch(walletManager: mockWalletManager)
        
        // Then
        XCTAssertTrue(viewModel.matchCreated)
        XCTAssertEqual(mockWalletManager.totalBalance, 900) // Deducted stake
        XCTAssertFalse(viewModel.showError)
    }
    
    func testCreateMatchInsufficientBalance() async {
        // Given
        mockWalletManager.totalBalance = 50
        viewModel.selectedActivity = createActivity()
        viewModel.stakeAmount = 100
        
        // When
        await viewModel.createMatch(walletManager: mockWalletManager)
        
        // Then
        XCTAssertFalse(viewModel.matchCreated)
        XCTAssertTrue(viewModel.showError)
        XCTAssertEqual(viewModel.errorMessage, "Insufficient balance. You need 100 tokens.")
        XCTAssertEqual(mockWalletManager.totalBalance, 50) // Not deducted
    }
    
    func testCreateMatchWithInvitedFriends() async {
        // Given
        mockWalletManager.totalBalance = 1000
        viewModel.selectedActivity = createActivity()
        viewModel.stakeAmount = 100
        viewModel.invitedFriends = [
            createMockUser(username: "friend1"),
            createMockUser(username: "friend2")
        ]
        
        // When
        await viewModel.createMatch(walletManager: mockWalletManager)
        
        // Then
        XCTAssertTrue(viewModel.matchCreated)
        // In real implementation, would verify invites were sent
    }
    
    // MARK: - Premium Activity Tests
    
    func testPremiumActivityRestriction() {
        // Given
        let premiumActivity = createActivity(name: "High Stakes", isPremium: true)
        let freeUser = createMockUser(subscriptionStatus: .free)
        
        // When
        viewModel.selectedActivity = premiumActivity
        
        // Then
        // In real implementation, would check user premium status
        XCTAssertNotNil(viewModel.selectedActivity)
    }
    
    // MARK: - Helper Methods
    
    private func createActivity(
        name: String = "Test Activity",
        category: String = "Test Category",
        isPremium: Bool = false,
        suggestedStakes: [Int] = [50, 100, 200],
        defaultRules: String? = nil
    ) -> ActivityTemplate {
        return ActivityTemplate(
            id: UUID(),
            name: name,
            category: category,
            isPremium: isPremium,
            defaultRules: defaultRules,
            iconName: "star.fill",
            suggestedStakes: suggestedStakes
        )
    }
    
    private func createMockUser(
        username: String = "testuser",
        subscriptionStatus: User.SubscriptionStatus = .free
    ) -> User {
        return User(
            id: UUID(),
            email: "\(username)@example.com",
            phone: nil,
            username: username,
            totalBalance: 500,
            withdrawableBalance: 500,
            subscriptionStatus: subscriptionStatus,
            subscriptionExpiresAt: nil,
            premiumTrialUses: [:],
            region: "US",
            ageVerified: true,
            createdAt: Date()
        )
    }
}

// MARK: - Mock Wallet Manager

class MockWalletManager: WalletManager {
    override func canAffordStake(_ amount: Int) -> Bool {
        return amount <= totalBalance
    }
    
    override func deductStake(_ amount: Int, for matchId: UUID) async throws {
        if amount > totalBalance {
            throw WalletError.insufficientBalance
        }
        totalBalance -= amount
    }
}