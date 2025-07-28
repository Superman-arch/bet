import Foundation

enum Environment {
    static let supabaseURL = URL(string: "YOUR_SUPABASE_URL")!
    static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"
    static let stripePublishableKey = "YOUR_STRIPE_PUBLISHABLE_KEY"
    
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