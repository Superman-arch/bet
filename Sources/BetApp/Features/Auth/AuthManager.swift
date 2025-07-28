import Foundation
import LocalAuthentication
import SwiftUI

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authError: String?
    @Published var isLoading = false
    
    private let keychain = KeychainManager()
    
    func checkAuthState() async {
        if let savedToken = keychain.getAuthToken() {
            // Verify token with Supabase
            await refreshSession()
        }
    }
    
    func signUp(email: String, password: String, username: String, phone: String?, region: String, age: Int) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let user = try await SupabaseManager.shared.signUp(
                email: email,
                password: password,
                username: username,
                phone: phone,
                region: region
            )
            
            currentUser = user
            isAuthenticated = true
            
            // Save auth token
            keychain.saveAuthToken("dummy_token") // Replace with actual token
            
            // Track analytics
            AnalyticsManager.shared.track(event: Environment.AnalyticsEvents.userSignedUp)
        } catch {
            authError = error.localizedDescription
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let user = try await SupabaseManager.shared.signIn(email: email, password: password)
            currentUser = user
            isAuthenticated = true
            
            // Save auth token
            keychain.saveAuthToken("dummy_token") // Replace with actual token
            
            // Track analytics
            AnalyticsManager.shared.track(event: Environment.AnalyticsEvents.userSignedIn)
        } catch {
            authError = error.localizedDescription
            throw error
        }
    }
    
    func signOut() async {
        do {
            try await SupabaseManager.shared.signOut()
            currentUser = nil
            isAuthenticated = false
            keychain.deleteAuthToken()
        } catch {
            authError = error.localizedDescription
        }
    }
    
    func authenticateWithBiometrics() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        
        do {
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to access your Bet account"
            )
            return result
        } catch {
            return false
        }
    }
    
    private func refreshSession() async {
        // Refresh the session with Supabase
        // Update currentUser and isAuthenticated
    }
}

class KeychainManager {
    private let service = Environment.keychainServiceIdentifier
    
    func saveAuthToken(_ token: String) {
        let data = token.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "authToken",
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func getAuthToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "authToken",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    func deleteAuthToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "authToken"
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}