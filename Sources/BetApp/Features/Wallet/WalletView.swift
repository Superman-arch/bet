import SwiftUI

struct WalletView: View {
    @EnvironmentObject var walletManager: WalletManager
    @State private var showingDeposit = false
    @State private var showingWithdraw = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Balance Card
                    BalanceCard(
                        totalBalance: walletManager.totalBalance,
                        withdrawableBalance: walletManager.withdrawableBalance
                    )
                    .padding(.horizontal)
                    
                    // Action Buttons
                    HStack(spacing: 15) {
                        Button {
                            showingDeposit = true
                        } label: {
                            Label("Add Tokens", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
                        Button {
                            showingWithdraw = true
                        } label: {
                            Label("Withdraw", systemImage: "arrow.down.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(walletManager.withdrawableBalance == 0)
                    }
                    .padding(.horizontal)
                    
                    // Transaction History
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Transaction History")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if walletManager.transactions.isEmpty {
                            EmptyStateView(
                                icon: "clock.arrow.circlepath",
                                title: "No Transactions Yet",
                                message: "Your transaction history will appear here"
                            )
                            .padding(.vertical, 40)
                        } else {
                            ForEach(walletManager.transactions) { transaction in
                                TransactionRow(transaction: transaction)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Wallet")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .refreshable {
                await walletManager.fetchBalance()
                await walletManager.fetchTransactions()
            }
            .sheet(isPresented: $showingDeposit) {
                DepositView()
            }
            .sheet(isPresented: $showingWithdraw) {
                WithdrawView()
            }
            .task {
                await walletManager.fetchTransactions()
            }
        }
    }
}

struct BalanceCard: View {
    let totalBalance: Int
    let withdrawableBalance: Int
    @State private var showingInfo = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 5) {
                Text("Total Balance")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Image(systemName: "dollarsign")
                        .font(.title2)
                    Text("\(totalBalance)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                        .animation(.spring(), value: totalBalance)
                }
                .foregroundColor(.primary)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Label("Withdrawable", systemImage: "banknote")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(withdrawableBalance) tokens")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .contentTransition(.numericText())
                        .animation(.spring(), value: withdrawableBalance)
                }
                
                Spacer()
                
                Button {
                    showingInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.1))
        )
        .alert("Balance Information", isPresented: $showingInfo) {
            Button("OK") { }
        } message: {
            Text("Total Balance includes all your tokens. Withdrawable Balance excludes bonus tokens and can be cashed out anytime.")
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var icon: String {
        switch transaction.type {
        case .deposit: return "arrow.down.circle.fill"
        case .withdrawal: return "arrow.up.circle.fill"
        case .matchStake: return "gamecontroller.fill"
        case .matchPayout: return "trophy.fill"
        case .matchRefund: return "arrow.uturn.backward.circle.fill"
        case .bonus: return "gift.fill"
        case .fee: return "minus.circle.fill"
        }
    }
    
    var color: Color {
        switch transaction.type {
        case .deposit, .matchPayout, .matchRefund, .bonus:
            return .green
        case .withdrawal, .matchStake, .fee:
            return .red
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.type.displayName)
                    .fontWeight(.medium)
                
                Text(transaction.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(transaction.amount > 0 ? "+" : "")\(transaction.amount)")
                .font(.headline)
                .foregroundColor(color)
        }
        .padding(.vertical, 8)
    }
}

struct DepositView: View {
    @EnvironmentObject var walletManager: WalletManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedPackage: TokenPackage?
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Select Token Package")
                        .font(.headline)
                        .padding(.top)
                    
                    ForEach(TokenPackage.packages, id: \.tokens) { package in
                        TokenPackageCard(
                            package: package,
                            isSelected: selectedPackage?.tokens == package.tokens
                        ) {
                            withAnimation(.spring()) {
                                selectedPackage = package
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    if let selected = selectedPackage {
                        VStack(spacing: 15) {
                            HStack {
                                Text("Total")
                                    .font(.headline)
                                Spacer()
                                Text(String(format: "$%.2f", selected.price))
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            Button {
                                Task {
                                    await processPurchase()
                                }
                            } label: {
                                if isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Label("Purchase Tokens", systemImage: "creditcard.fill")
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(isProcessing)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Add Tokens")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .trailingBar) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func processPurchase() async {
        guard let package = selectedPackage else { return }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            try await walletManager.purchaseTokens(
                amount: package.price,
                bonusPercentage: package.bonusPercentage
            )
            
            await MainActor.run {
                HapticManager.success()
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.error()
        }
    }
}

struct TokenPackageCard: View {
    let package: TokenPackage
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                if package.popular {
                    Text("MOST POPULAR")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.accentColor)
                        .cornerRadius(5)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(package.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if package.bonusPercentage > 0 {
                            Text("Best Value!")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Spacer()
                    
                    Text("$\(package.price, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct WithdrawView: View {
    @EnvironmentObject var walletManager: WalletManager
    @Environment(\.dismiss) var dismiss
    @State private var withdrawAmount = ""
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var tokenAmount: Int {
        Int(withdrawAmount) ?? 0
    }
    
    var dollarAmount: Double {
        Double(tokenAmount) / 100.0
    }
    
    var canWithdraw: Bool {
        tokenAmount > 0 && tokenAmount <= walletManager.withdrawableBalance
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                VStack(spacing: 10) {
                    Text("Withdrawable Balance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(walletManager.withdrawableBalance) tokens")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("($\(Double(walletManager.withdrawableBalance) / 100.0, specifier: "%.2f"))")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                VStack(spacing: 20) {
                    CustomTextField(
                        placeholder: "Amount to withdraw",
                        text: $withdrawAmount,
                        icon: "dollarsign",
                        keyboardType: .numberPad
                    )
                    
                    if tokenAmount > 0 {
                        Text("You will receive: $\(dollarAmount, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    
                    if tokenAmount > walletManager.withdrawableBalance {
                        Text("Insufficient withdrawable balance")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button {
                    Task {
                        await processWithdrawal()
                    }
                } label: {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Label("Withdraw to Bank", systemImage: "building.columns.fill")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canWithdraw || isProcessing)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("Withdraw Tokens")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .trailingBar) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func processWithdrawal() async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            try await walletManager.withdrawTokens(amount: tokenAmount)
            
            await MainActor.run {
                HapticManager.success()
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.error()
        }
    }
}

extension Transaction.TransactionType {
    var displayName: String {
        switch self {
        case .deposit: return "Deposit"
        case .withdrawal: return "Withdrawal"
        case .matchStake: return "Match Stake"
        case .matchPayout: return "Match Winnings"
        case .matchRefund: return "Match Refund"
        case .bonus: return "Bonus"
        case .fee: return "Processing Fee"
        }
    }
}