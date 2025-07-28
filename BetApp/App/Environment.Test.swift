import Foundation

// Test environment configuration
// Copy this to Environment.swift for testing
enum TestEnvironment {
    // Local Supabase
    static let supabaseURL = URL(string: "http://localhost:54321")!
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
    
    // Stripe Test Keys
    static let stripePublishableKey = "pk_test_51234567890abcdefghijklmnopqrstuvwxyz"
    
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