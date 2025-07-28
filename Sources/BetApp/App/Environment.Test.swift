import Foundation

// Test environment configuration
// Copy this to Environment.swift for testing
enum TestEnvironment {
    // Test Supabase (using the same test instance)
    static let supabaseURL = URL(string: "https://kcuauyodflebjjhylpdh.supabase.co")!
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtjdWF1eW9kZmxlYmpqaHlscGRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM2NjU4NjAsImV4cCI6MjA2OTI0MTg2MH0.QaE7Pj8f8q9bcDielRNgLJj9Z1FxMJiU8E0kqsy8j7A"
    
    // Stripe Test Keys
    static let stripePublishableKey = "pk_test_51Rpg1LL3mmYK3GIhMNYJEfmORQJoZyjEjrjFDuEp3KTNoHIZW7Ryc3yIEv2gG7R923I4j87Eo0CFSwS9YtBTCKqP009jRTC1oG"
    
    // Test Configuration
    static let isTestEnvironment = true
    static let mockPayments = true
    static let skipBiometrics = true
    
    // Test API URLs
    static var apiBaseURL: URL {
        return URL(string: "http://localhost:8080")!
    }
    
    // Test Users
    struct TestUsers {
        static let freeUser = (
            email: "free@test.com",
            password: "Test123!",
            username: "test_free"
        )
        
        static let premiumUser = (
            email: "premium@test.com",
            password: "Test123!",
            username: "test_premium"
        )
        
        static let richUser = (
            email: "rich@test.com",
            password: "Test123!",
            username: "test_rich",
            balance: 10000
        )
    }
    
    // Test Data
    static let testRegions = [
        "United States",
        "Test Region",
        "Restricted Region"
    ]
    
    static let testActivities = [
        "Test Chess",
        "Test Poker",
        "Test Basketball"
    ]
}