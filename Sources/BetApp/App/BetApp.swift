import SwiftUI

@main
struct BetApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var authManager = AuthManager()
    @StateObject private var supabaseManager = SupabaseManager()
    @StateObject private var walletManager = WalletManager()
    @StateObject private var notificationManager = NotificationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(authManager)
                .environmentObject(supabaseManager)
                .environmentObject(walletManager)
                .environmentObject(notificationManager)
                .preferredColorScheme(.dark)
                .task {
                    await initializeApp()
                }
        }
    }
    
    private func initializeApp() async {
        await notificationManager.requestAuthorization()
        await authManager.checkAuthState()
        
        if authManager.isAuthenticated {
            await walletManager.fetchBalance()
        }
    }
}

class AppState: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var showingOnboarding = false
    @Published var currentUser: User?
    @Published var isLoading = false
    
    enum Tab {
        case home
        case matches
        case wallet
        case social
        case profile
    }
}