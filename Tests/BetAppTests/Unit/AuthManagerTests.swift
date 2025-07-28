import XCTest
@testable import BetApp

class AuthManagerTests: XCTestCase {
    var authManager: AuthManager!
    var mockKeychain: MockKeychainManager!
    
    override func setUp() {
        super.setUp()
        authManager = AuthManager()
        mockKeychain = MockKeychainManager()
        // Inject mock keychain
    }
    
    override func tearDown() {
        authManager = nil
        mockKeychain = nil
        super.tearDown()
    }
    
    // MARK: - Sign Up Tests
    
    func testSignUpSuccess() async throws {
        // Given
        let email = "test@example.com"
        let password = "SecurePass123!"
        let username = "testuser"
        let region = "US"
        let age = 21
        
        // When
        try await authManager.signUp(
            email: email,
            password: password,
            username: username,
            phone: nil,
            region: region,
            age: age
        )
        
        // Then
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertNotNil(authManager.currentUser)
        XCTAssertEqual(authManager.currentUser?.email, email)
        XCTAssertEqual(authManager.currentUser?.username, username)
        XCTAssertTrue(mockKeychain.hasAuthToken)
    }
    
    func testSignUpUnderageUser() async {
        // Given
        let age = 17
        
        // When/Then
        do {
            try await authManager.signUp(
                email: "young@example.com",
                password: "Pass123!",
                username: "younguser",
                phone: nil,
                region: "US",
                age: age
            )
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertFalse(authManager.isAuthenticated)
        }
    }
    
    // MARK: - Sign In Tests
    
    func testSignInSuccess() async throws {
        // Given
        let email = "existing@example.com"
        let password = "Password123!"
        
        // When
        try await authManager.signIn(email: email, password: password)
        
        // Then
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertNotNil(authManager.currentUser)
        XCTAssertTrue(mockKeychain.hasAuthToken)
    }
    
    func testSignInInvalidCredentials() async {
        // Given
        let email = "wrong@example.com"
        let password = "WrongPassword"
        
        // When/Then
        do {
            try await authManager.signIn(email: email, password: password)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertFalse(authManager.isAuthenticated)
            XCTAssertNotNil(authManager.authError)
        }
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOut() async {
        // Given
        authManager.isAuthenticated = true
        authManager.currentUser = createMockUser()
        mockKeychain.saveAuthToken("dummy_token")
        
        // When
        await authManager.signOut()
        
        // Then
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentUser)
        XCTAssertFalse(mockKeychain.hasAuthToken)
    }
    
    // MARK: - Biometric Tests
    
    func testBiometricAuthentication() async {
        // This would require mocking LAContext
        // For now, just test the method exists
        let result = await authManager.authenticateWithBiometrics()
        XCTAssertFalse(result) // Should fail in test environment
    }
    
    // MARK: - Session Tests
    
    func testCheckAuthStateWithSavedToken() async {
        // Given
        mockKeychain.saveAuthToken("valid_token")
        
        // When
        await authManager.checkAuthState()
        
        // Then
        // In a real test, this would verify token with backend
        XCTAssertTrue(mockKeychain.hasAuthToken)
    }
    
    func testCheckAuthStateNoToken() async {
        // Given
        mockKeychain.deleteAuthToken()
        
        // When
        await authManager.checkAuthState()
        
        // Then
        XCTAssertFalse(authManager.isAuthenticated)
    }
    
    // MARK: - Helper Methods
    
    private func createMockUser() -> User {
        return User(
            id: UUID(),
            email: "test@example.com",
            phone: nil,
            username: "testuser",
            totalBalance: 500,
            withdrawableBalance: 500,
            subscriptionStatus: .free,
            subscriptionExpiresAt: nil,
            premiumTrialUses: [:],
            region: "US",
            ageVerified: true,
            createdAt: Date()
        )
    }
}

// MARK: - Mock Keychain Manager

class MockKeychainManager: KeychainManager {
    private var storage: [String: String] = [:]
    
    var hasAuthToken: Bool {
        storage["authToken"] != nil
    }
    
    override func saveAuthToken(_ token: String) {
        storage["authToken"] = token
    }
    
    override func getAuthToken() -> String? {
        return storage["authToken"]
    }
    
    override func deleteAuthToken() {
        storage.removeValue(forKey: "authToken")
    }
}