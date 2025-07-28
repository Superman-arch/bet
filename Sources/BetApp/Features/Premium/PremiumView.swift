import SwiftUI
import StoreKit

struct PremiumView: View {
    @StateObject private var viewModel = PremiumViewModel()
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss: DismissAction
    @State private var selectedPlan: SubscriptionPlan = .monthly
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Hero Section
                    VStack(spacing: 20) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.yellow)
                            .symbolEffect(.bounce, value: viewModel.animationTrigger)
                        
                        VStack(spacing: 10) {
                            Text("Upgrade to Bet+")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Unlock premium features and maximize your winnings")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 30)
                    
                    // Benefits Section
                    VStack(spacing: 15) {
                        BenefitRow(
                            icon: "percent",
                            title: "Zero Processing Fees",
                            description: "Keep 100% of your winnings"
                        )
                        
                        BenefitRow(
                            icon: "star.fill",
                            title: "Exclusive Activities",
                            description: "Access premium games and high-stakes matches"
                        )
                        
                        BenefitRow(
                            icon: "bolt.fill",
                            title: "Priority Features",
                            description: "First access to new features and updates"
                        )
                        
                        BenefitRow(
                            icon: "chart.bar.fill",
                            title: "Advanced Analytics",
                            description: "Detailed match statistics and insights"
                        )
                        
                        BenefitRow(
                            icon: "headphones",
                            title: "VIP Support",
                            description: "Priority customer support 24/7"
                        )
                        
                        BenefitRow(
                            icon: "sparkles",
                            title: "Profile Badge",
                            description: "Exclusive Bet+ badge and profile customization"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Pricing Plans
                    VStack(spacing: 15) {
                        Text("Choose Your Plan")
                            .font(.headline)
                        
                        ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                            PlanCard(
                                plan: plan,
                                isSelected: selectedPlan == plan,
                                onSelect: {
                                    withAnimation {
                                        selectedPlan = plan
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Subscribe Button
                    Button {
                        Task {
                            await viewModel.subscribe(to: selectedPlan)
                        }
                    } label: {
                        if viewModel.isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Start Free Trial")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isProcessing)
                    .padding(.horizontal)
                    
                    // Terms
                    VStack(spacing: 5) {
                        Text("Start with a 7-day free trial")
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        Text("Cancel anytime. Auto-renews after trial.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            Button("Terms of Service") {
                                // Open terms
                            }
                            
                            Button("Privacy Policy") {
                                // Open privacy
                            }
                        }
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Bet+ Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Restore") {
                        Task {
                            await viewModel.restorePurchases()
                        }
                    }
                }
            }
            .alert("Success!", isPresented: $viewModel.showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Welcome to Bet+! Your premium features are now active.")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.yellow)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void
    
    var savings: String? {
        switch plan {
        case .monthly:
            return nil
        case .yearly:
            return "Save 17%"
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(plan.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(plan.price)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 5) {
                        if let savings = savings {
                            Text(savings)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(5)
                        }
                        
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? .accentColor : .secondary)
                            .font(.title2)
                    }
                }
                
                if plan == .yearly {
                    Text("Best Value")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum SubscriptionPlan: CaseIterable {
    case monthly
    case yearly
    
    var name: String {
        switch self {
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Annual"
        }
    }
    
    var price: String {
        switch self {
        case .monthly:
            return "$4.99/month"
        case .yearly:
            return "$49.99/year"
        }
    }
    
    var productId: String {
        switch self {
        case .monthly:
            return "com.betapp.premium.monthly"
        case .yearly:
            return "com.betapp.premium.yearly"
        }
    }
}

class PremiumViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var showSuccess = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var animationTrigger = 0
    
    private var products: [Product] = []
    private var purchaseTask: Task<Void, Never>?
    
    init() {
        Task {
            await loadProducts()
        }
    }
    
    @MainActor
    private func loadProducts() async {
        do {
            // Load StoreKit products
            let productIds = SubscriptionPlan.allCases.map { $0.productId }
            // products = try await Product.products(for: productIds)
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    @MainActor
    func subscribe(to plan: SubscriptionPlan) async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Find the product for the selected plan
            guard let product = products.first(where: { $0.id == plan.productId }) else {
                throw PremiumError.productNotFound
            }
            
            // Purchase the product
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Handle successful purchase
                switch verification {
                case .verified(let transaction):
                    // Update user's premium status
                    await updatePremiumStatus()
                    
                    // Finish the transaction
                    await transaction.finish()
                    
                    showSuccess = true
                    animationTrigger += 1
                    HapticManager.success()
                    
                case .unverified:
                    throw PremiumError.verificationFailed
                }
                
            case .userCancelled:
                // User cancelled, do nothing
                break
                
            case .pending:
                // Purchase is pending (e.g., waiting for approval)
                errorMessage = "Purchase is pending approval"
                showError = true
                
            @unknown default:
                throw PremiumError.unknownError
            }
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.error()
        }
    }
    
    @MainActor
    func restorePurchases() async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Restore purchases
            try await AppStore.sync()
            
            // Check for active subscriptions
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    // Check if this is a premium subscription
                    if SubscriptionPlan.allCases.contains(where: { $0.productId == transaction.productID }) {
                        await updatePremiumStatus()
                        showSuccess = true
                        return
                    }
                case .unverified:
                    continue
                }
            }
            
            errorMessage = "No active subscription found"
            showError = true
            
        } catch {
            errorMessage = "Failed to restore purchases"
            showError = true
        }
    }
    
    private func updatePremiumStatus() async {
        // Update user's premium status in Supabase
        // This would typically involve calling an API endpoint
    }
}

enum PremiumError: LocalizedError {
    case productNotFound
    case verificationFailed
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found. Please try again later."
        case .verificationFailed:
            return "Purchase verification failed."
        case .unknownError:
            return "An unknown error occurred."
        }
    }
}