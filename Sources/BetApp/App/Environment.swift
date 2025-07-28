import Foundation

enum Environment {
    static let supabaseURL = URL(string: "https://kcuauyodflebjjhylpdh.supabase.co")!
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtjdWF1eW9kZmxlYmpqaHlscGRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM2NjU4NjAsImV4cCI6MjA2OTI0MTg2MH0.QaE7Pj8f8q9bcDielRNgLJj9Z1FxMJiU8E0kqsy8j7A"
    static let stripePublishableKey = "pk_test_51Rpg1LL3mmYK3GIhMNYJEfmORQJoZyjEjrjFDuEp3KTNoHIZW7Ryc3yIEv2gG7R923I4j87Eo0CFSwS9YtBTCKqP009jRTC1oG"
    
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var apiBaseURL: URL {
        if isDebug {
            return URL(string: "http://localhost:8080")!
        } else {
            return URL(string: "https://api.betapp.com")!
        }
    }
    
    static let appGroupIdentifier = "group.com.betapp.bet"
    static let keychainServiceIdentifier = "com.betapp.bet"
    
    enum UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let userRegion = "userRegion"
        static let ageVerified = "ageVerified"
        static let notificationPreferences = "notificationPreferences"
        static let biometricEnabled = "biometricEnabled"
    }
    
    enum AnalyticsEvents {
        static let appLaunched = "app_launched"
        static let userSignedUp = "user_signed_up"
        static let userSignedIn = "user_signed_in"
        static let matchCreated = "match_created"
        static let matchJoined = "match_joined"
        static let tokensPurchased = "tokens_purchased"
        static let tokensWithdrawn = "tokens_withdrawn"
        static let premiumSubscribed = "premium_subscribed"
    }
}