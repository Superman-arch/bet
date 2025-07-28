import XCTest
@testable import BetApp

class WalletManagerTests: XCTestCase {
    var walletManager: WalletManager!
    var mockSupabase: MockSupabaseManager!
    
    override func setUp() {
        super.setUp()
        mockSupabase = MockSupabaseManager()
        walletManager = WalletManager()
        // Inject mock
    }
    
    override func tearDown() {
        walletManager = nil
        mockSupabase = nil
        super.tearDown()
    }
    
    // MARK: - Balance Tests
    
    func testInitialBalance() {
        XCTAssertEqual(walletManager.totalBalance, 0)
        XCTAssertEqual(walletManager.withdrawableBalance, 0)
    }
    
    func testFetchBalance() async {
        // Given
        mockSupabase.mockUser = User(
            id: UUID(),
            email: "test@example.com",
            phone: nil,
            username: "testuser",
            totalBalance: 1000,
            withdrawableBalance: 800,
            subscriptionStatus: .free,
            subscriptionExpiresAt: nil,
            premiumTrialUses: [:],
            region: "US",
            ageVerified: true,
            createdAt: Date()
        )
        
        // When
        await walletManager.fetchBalance()
        
        // Then
        XCTAssertEqual(walletManager.totalBalance, 1000)
        XCTAssertEqual(walletManager.withdrawableBalance, 800)
    }
    
    // MARK: - Purchase Tests
    
    func testPurchaseTokensWithBonus() async throws {
        // Given
        walletManager.totalBalance = 500
        walletManager.withdrawableBalance = 500
        
        // When - Purchase $10 package (10% bonus)
        try await walletManager.purchaseTokens(amount: 10.0, bonusPercentage: 0.10)
        
        // Then
        XCTAssertEqual(walletManager.totalBalance, 1600) // 500 + 1000 + 100 bonus
        XCTAssertEqual(walletManager.withdrawableBalance, 1500) // 500 + 1000 (bonus not withdrawable)
    }
    
    func testPurchaseTokensFailure() async {
        // Given
        mockSupabase.shouldFailPayment = true
        
        // When/Then
        do {
            try await walletManager.purchaseTokens(amount: 10.0)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(error as? WalletError, WalletError.paymentFailed)
        }
    }
    
    // MARK: - Withdrawal Tests
    
    func testWithdrawTokensSuccess() async throws {
        // Given
        walletManager.totalBalance = 1000
        walletManager.withdrawableBalance = 800
        
        // When
        try await walletManager.withdrawTokens(amount: 500)
        
        // Then
        XCTAssertEqual(walletManager.totalBalance, 500)
        XCTAssertEqual(walletManager.withdrawableBalance, 300)
    }
    
    func testWithdrawInsufficientBalance() async {
        // Given
        walletManager.totalBalance = 1000
        walletManager.withdrawableBalance = 300
        
        // When/Then
        do {
            try await walletManager.withdrawTokens(amount: 500)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(error as? WalletError, WalletError.insufficientWithdrawableBalance)
        }
    }
    
    func testWithdrawComplianceRestriction() async {
        // Given
        walletManager.withdrawableBalance = 1000
        mockSupabase.mockComplianceRestriction = "Daily limit exceeded"
        
        // When/Then
        do {
            try await walletManager.withdrawTokens(amount: 500)
            XCTFail("Should have thrown error")
        } catch WalletError.complianceRestriction(let reason) {
            XCTAssertEqual(reason, "Daily limit exceeded")
        } catch {
            XCTFail("Wrong error type")
        }
    }
    
    // MARK: - Stake Tests
    
    func testCanAffordStake() {
        walletManager.totalBalance = 500
        
        XCTAssertTrue(walletManager.canAffordStake(100))
        XCTAssertTrue(walletManager.canAffordStake(500))
        XCTAssertFalse(walletManager.canAffordStake(501))
    }
    
    func testDeductStake() async throws {
        // Given
        walletManager.totalBalance = 1000
        let matchId = UUID()
        
        // When
        try await walletManager.deductStake(200, for: matchId)
        
        // Then
        XCTAssertEqual(walletManager.totalBalance, 800)
        XCTAssertEqual(walletManager.transactions.count, 1)
        XCTAssertEqual(walletManager.transactions.first?.amount, -200)
        XCTAssertEqual(walletManager.transactions.first?.type, .matchStake)
    }
    
    func testAddWinnings() async throws {
        // Given
        walletManager.totalBalance = 500
        walletManager.withdrawableBalance = 400
        let matchId = UUID()
        
        // When
        try await walletManager.addWinnings(300, from: matchId, isWithdrawable: true)
        
        // Then
        XCTAssertEqual(walletManager.totalBalance, 800)
        XCTAssertEqual(walletManager.withdrawableBalance, 700)
    }
    
    // MARK: - Transaction Tests
    
    func testFetchTransactions() async {
        // Given
        mockSupabase.mockTransactions = [
            Transaction(
                id: UUID(),
                userId: UUID(),
                amount: 100,
                type: .deposit,
                subtype: nil,
                relatedMatchId: nil,
                stripePaymentIntentId: nil,
                bonusAmount: 10,
                createdAt: Date()
            ),
            Transaction(
                id: UUID(),
                userId: UUID(),
                amount: -50,
                type: .matchStake,
                subtype: nil,
                relatedMatchId: UUID(),
                stripePaymentIntentId: nil,
                bonusAmount: 0,
                createdAt: Date()
            )
        ]
        
        // When
        await walletManager.fetchTransactions()
        
        // Then
        XCTAssertEqual(walletManager.transactions.count, 2)
        XCTAssertEqual(walletManager.transactions[0].type, .deposit)
        XCTAssertEqual(walletManager.transactions[1].type, .matchStake)
    }
}

// MARK: - Mock Supabase Manager

class MockSupabaseManager: SupabaseManager {
    var mockUser: User?
    var mockTransactions: [Transaction] = []
    var shouldFailPayment = false
    var mockComplianceRestriction: String?
    
    override func fetchUser(id: UUID) async throws -> User {
        guard let user = mockUser else {
            throw NSError(domain: "Test", code: 0)
        }
        return user
    }
    
    override func fetchTransactions(for userId: UUID?) async throws -> [Transaction] {
        return mockTransactions
    }
    
    override func createTransaction(type: Transaction.TransactionType, amount: Int, relatedMatchId: UUID?) async throws -> Transaction {
        if shouldFailPayment && type == .deposit {
            throw WalletError.paymentFailed
        }
        
        let transaction = Transaction(
            id: UUID(),
            userId: mockUser?.id ?? UUID(),
            amount: amount,
            type: type,
            subtype: nil,
            relatedMatchId: relatedMatchId,
            stripePaymentIntentId: nil,
            bonusAmount: 0,
            createdAt: Date()
        )
        
        mockTransactions.append(transaction)
        return transaction
    }
}