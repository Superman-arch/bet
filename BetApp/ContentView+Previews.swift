import SwiftUI

// MARK: - SwiftUI Previews for Key Screens

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // Main app view
        ContentView()
            .environmentObject(AppState())
            .environmentObject(AuthManager())
            .environmentObject(SupabaseManager())
            .environmentObject(WalletManager())
            .environmentObject(NotificationManager())
            .previewDisplayName("Main App")
        
        // Dark mode
        ContentView()
            .environmentObject(AppState())
            .environmentObject(AuthManager())
            .environmentObject(SupabaseManager())
            .environmentObject(WalletManager())
            .environmentObject(NotificationManager())
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
    }
}

// MARK: - Onboarding Previews

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Welcome screen
            NavigationStack {
                WelcomeView()
            }
            .previewDisplayName("Welcome")
            
            // Age verification
            NavigationStack {
                AgeVerificationView(viewModel: OnboardingViewModel())
            }
            .previewDisplayName("Age Verification")
            
            // Region selection
            NavigationStack {
                RegionSelectionView(viewModel: OnboardingViewModel())
            }
            .previewDisplayName("Region Selection")
            
            // Account creation
            NavigationStack {
                AccountSetupView(viewModel: OnboardingViewModel())
                    .environmentObject(AuthManager())
            }
            .previewDisplayName("Account Setup")
        }
    }
}

// MARK: - Home Screen Previews

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
                .environmentObject(createMockWalletManager())
                .environmentObject(createMockAuthManager())
        }
        .previewDisplayName("Home Dashboard")
    }
    
    static func createMockWalletManager() -> WalletManager {
        let manager = WalletManager()
        manager.totalBalance = 2500
        manager.withdrawableBalance = 2000
        return manager
    }
    
    static func createMockAuthManager() -> AuthManager {
        let manager = AuthManager()
        manager.currentUser = User(
            id: UUID(),
            email: "preview@test.com",
            phone: nil,
            username: "preview_user",
            totalBalance: 2500,
            withdrawableBalance: 2000,
            subscriptionStatus: .free,
            subscriptionExpiresAt: nil,
            premiumTrialUses: [:],
            region: "United States",
            ageVerified: true,
            createdAt: Date()
        )
        manager.isAuthenticated = true
        return manager
    }
}

// MARK: - Wallet Previews

struct WalletView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // With balance
            NavigationStack {
                WalletView()
                    .environmentObject(createWalletWithBalance())
            }
            .previewDisplayName("With Balance")
            
            // Empty wallet
            NavigationStack {
                WalletView()
                    .environmentObject(createEmptyWallet())
            }
            .previewDisplayName("Empty Wallet")
        }
    }
    
    static func createWalletWithBalance() -> WalletManager {
        let manager = WalletManager()
        manager.totalBalance = 5000
        manager.withdrawableBalance = 4500
        manager.transactions = [
            Transaction(
                id: UUID(),
                userId: UUID(),
                amount: 1000,
                type: .deposit,
                subtype: nil,
                relatedMatchId: nil,
                stripePaymentIntentId: nil,
                bonusAmount: 100,
                createdAt: Date()
            ),
            Transaction(
                id: UUID(),
                userId: UUID(),
                amount: -200,
                type: .matchStake,
                subtype: nil,
                relatedMatchId: UUID(),
                stripePaymentIntentId: nil,
                bonusAmount: 0,
                createdAt: Date().addingTimeInterval(-3600)
            )
        ]
        return manager
    }
    
    static func createEmptyWallet() -> WalletManager {
        return WalletManager()
    }
}

// MARK: - Match Creation Previews

struct CreateMatchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CreateMatchView()
                .environmentObject(WalletManager())
        }
        .previewDisplayName("Create Match")
    }
}

// MARK: - Social Previews

struct SocialView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Friends tab
            NavigationStack {
                SocialView()
            }
            .previewDisplayName("Friends List")
            
            // Leaderboard
            NavigationStack {
                LeaderboardView()
            }
            .previewDisplayName("Leaderboard")
        }
    }
}

// MARK: - Premium Previews

struct PremiumView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PremiumView()
                .environmentObject(AuthManager())
        }
        .previewDisplayName("Premium Subscription")
    }
}

// MARK: - Multiple Device Previews

struct MultiDevicePreview: PreviewProvider {
    static var previews: some View {
        ForEach(["iPhone 14 Pro", "iPhone 14 Pro Max", "iPhone SE (3rd generation)"], id: \.self) { device in
            ContentView()
                .environmentObject(AppState())
                .environmentObject(AuthManager())
                .environmentObject(SupabaseManager())
                .environmentObject(WalletManager())
                .environmentObject(NotificationManager())
                .previewDevice(PreviewDevice(rawValue: device))
                .previewDisplayName(device)
        }
    }
}

// MARK: - Component Previews

struct ComponentPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            // Balance card
            BalanceCard(totalBalance: 2500, withdrawableBalance: 2000)
                .padding()
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Balance Card")
            
            // Match card
            MatchCard(match: createSampleMatch()) { }
                .padding()
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Match Card")
            
            // Transaction row
            TransactionRow(transaction: createSampleTransaction())
                .padding()
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Transaction Row")
            
            // Empty state
            EmptyStateView(
                icon: "gamecontroller",
                title: "No Matches Yet",
                message: "Create a match or join one from a friend"
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Empty State")
        }
    }
    
    static func createSampleMatch() -> Match {
        Match(
            id: UUID(),
            creatorId: UUID(),
            activityType: "Chess",
            activityTemplateId: nil,
            customRules: nil,
            stakeAmount: 100,
            totalPot: 200,
            status: .active,
            isPremiumOnly: false,
            disputeProofUrl: nil,
            disputeDeadline: nil,
            createdAt: Date()
        )
    }
    
    static func createSampleTransaction() -> Transaction {
        Transaction(
            id: UUID(),
            userId: UUID(),
            amount: 500,
            type: .matchPayout,
            subtype: nil,
            relatedMatchId: UUID(),
            stripePaymentIntentId: nil,
            bonusAmount: 0,
            createdAt: Date()
        )
    }
}