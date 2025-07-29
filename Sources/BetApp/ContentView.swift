import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authManager: AuthManager
    @State private var showingOnboarding = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                SignInView()
            }
        }
        .onAppear {
            checkOnboardingStatus()
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView()
        }
        #else
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView()
                .frame(minWidth: 800, minHeight: 600)
        }
        #endif
    }
    
    private func checkOnboardingStatus() {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: AppEnvironment.UserDefaultsKeys.hasCompletedOnboarding)
        if !hasCompletedOnboarding && !authManager.isAuthenticated {
            showingOnboarding = true
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppState.Tab.home)
            
            MatchesView()
                .tabItem {
                    Label("Matches", systemImage: "gamecontroller.fill")
                }
                .tag(AppState.Tab.matches)
            
            WalletView()
                .tabItem {
                    Label("Wallet", systemImage: "dollarsign.circle.fill")
                }
                .tag(AppState.Tab.wallet)
            
            SocialView()
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }
                .tag(AppState.Tab.social)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(AppState.Tab.profile)
        }
        .tint(.accentColor)
    }
}