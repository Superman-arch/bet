import Foundation
import SwiftUI

class WalletManager: ObservableObject {
    @Published var totalBalance: Int = 0
    @Published var withdrawableBalance: Int = 0
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let supabase = SupabaseManager.shared
    
    func fetchBalance() async {
        guard let userId = supabase.currentUser?.id else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let user = try await supabase.fetchUser(id: userId)
            await MainActor.run {
                self.totalBalance = user.totalBalance
                self.withdrawableBalance = user.withdrawableBalance
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
    
    func purchaseTokens(amount: Double, bonusPercentage: Double = 0) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let tokenAmount = Int(amount * 100) // Convert dollars to tokens (1:100 ratio)
        let bonusAmount = Int(Double(tokenAmount) * bonusPercentage)
        let totalTokens = tokenAmount + bonusAmount
        
        // Process payment through Stripe
        let paymentSuccessful = try await StripeManager.shared.processPayment(amount: amount)
        
        if paymentSuccessful {
            // Update balances
            let transaction = try await supabase.createTransaction(
                type: .deposit,
                amount: totalTokens,
                relatedMatchId: nil
            )
            
            await MainActor.run {
                self.totalBalance += totalTokens
                self.withdrawableBalance += tokenAmount // Bonus tokens are not withdrawable
                self.transactions.insert(transaction, at: 0)
            }
            
            // Track analytics
            AnalyticsManager.shared.track(
                event: AppEnvironment.AnalyticsEvents.tokensPurchased,
                properties: [
                    "amount": amount,
                    "tokens": tokenAmount,
                    "bonus": bonusAmount
                ]
            )
        }
    }
    
    func withdrawTokens(amount: Int) async throws {
        guard amount <= withdrawableBalance else {
            throw WalletError.insufficientWithdrawableBalance
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Check compliance limits
        let compliance = try await ComplianceManager.shared.checkWithdrawalCompliance(amount: amount)
        guard compliance.isAllowed else {
            throw WalletError.complianceRestriction(compliance.reason ?? "Withdrawal restricted")
        }
        
        // Process withdrawal through Stripe
        let withdrawalAmount = Double(amount) / 100.0 // Convert tokens to dollars
        let withdrawalSuccessful = try await StripeManager.shared.processWithdrawal(amount: withdrawalAmount)
        
        if withdrawalSuccessful {
            // Update balances
            let transaction = try await supabase.createTransaction(
                type: .withdrawal,
                amount: -amount,
                relatedMatchId: nil
            )
            
            await MainActor.run {
                self.totalBalance -= amount
                self.withdrawableBalance -= amount
                self.transactions.insert(transaction, at: 0)
            }
            
            // Track analytics
            AnalyticsManager.shared.track(
                event: AppEnvironment.AnalyticsEvents.tokensWithdrawn,
                properties: ["amount": amount]
            )
        }
    }
    
    func fetchTransactions() async {
        guard let userId = supabase.currentUser?.id else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetchedTransactions = try await supabase.fetchTransactions(for: userId)
            await MainActor.run {
                self.transactions = fetchedTransactions
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
    
    func canAffordStake(_ amount: Int) -> Bool {
        return amount <= totalBalance
    }
    
    func deductStake(_ amount: Int, for matchId: UUID) async throws {
        guard canAffordStake(amount) else {
            throw WalletError.insufficientBalance
        }
        
        let transaction = try await supabase.createTransaction(
            type: .matchStake,
            amount: -amount,
            relatedMatchId: matchId
        )
        
        await MainActor.run {
            self.totalBalance -= amount
            self.transactions.insert(transaction, at: 0)
        }
    }
    
    func addWinnings(_ amount: Int, from matchId: UUID, isWithdrawable: Bool = true) async throws {
        let transaction = try await supabase.createTransaction(
            type: .matchPayout,
            amount: amount,
            relatedMatchId: matchId
        )
        
        await MainActor.run {
            self.totalBalance += amount
            if isWithdrawable {
                self.withdrawableBalance += amount
            }
            self.transactions.insert(transaction, at: 0)
        }
    }
}

enum WalletError: LocalizedError {
    case insufficientBalance
    case insufficientWithdrawableBalance
    case complianceRestriction(String)
    case paymentFailed
    
    var errorDescription: String? {
        switch self {
        case .insufficientBalance:
            return "Insufficient balance for this transaction"
        case .insufficientWithdrawableBalance:
            return "Insufficient withdrawable balance"
        case .complianceRestriction(let reason):
            return reason
        case .paymentFailed:
            return "Payment failed. Please try again."
        }
    }
}

struct TokenPackage {
    let tokens: Int
    let price: Double
    let bonusPercentage: Double
    let popular: Bool
    
    var displayName: String {
        if bonusPercentage > 0 {
            return "\(tokens.formatted()) tokens (+\(Int(bonusPercentage * 100))% bonus)"
        } else {
            return "\(tokens.formatted()) tokens"
        }
    }
    
    static let packages = [
        TokenPackage(tokens: 500, price: 5.00, bonusPercentage: 0, popular: false),
        TokenPackage(tokens: 1100, price: 10.00, bonusPercentage: 0.10, popular: false),
        TokenPackage(tokens: 2800, price: 25.00, bonusPercentage: 0.12, popular: true),
        TokenPackage(tokens: 6000, price: 50.00, bonusPercentage: 0.20, popular: false),
        TokenPackage(tokens: 13500, price: 100.00, bonusPercentage: 0.35, popular: false)
    ]
}