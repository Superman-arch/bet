import Foundation
import SwiftUI

class ComplianceManager: ObservableObject {
    static let shared = ComplianceManager()
    
    @Published var currentCompliance: ComplianceSettings?
    @Published var isRestricted = false
    @Published var restrictionReason: String?
    
    private let securityManager = SecurityManager()
    
    func checkEligibility(for region: String, age: Int) -> ComplianceStatus {
        // Check regional restrictions
        guard let compliance = loadComplianceSettings(for: region) else {
            return ComplianceStatus(isAllowed: false, reason: "Region not supported")
        }
        
        // Check if region is allowed
        guard compliance.isAllowed else {
            return ComplianceStatus(isAllowed: false, reason: "Betting not permitted in your region")
        }
        
        // Check age requirement
        guard age >= compliance.ageRequirement else {
            return ComplianceStatus(isAllowed: false, reason: "You must be at least \(compliance.ageRequirement) years old")
        }
        
        currentCompliance = compliance
        return ComplianceStatus(isAllowed: true, reason: nil)
    }
    
    func checkDepositCompliance(amount: Int, region: String) async throws -> ComplianceStatus {
        guard let compliance = currentCompliance else {
            return ComplianceStatus(isAllowed: false, reason: "Compliance not verified")
        }
        
        // Check daily deposit limit
        if let maxDaily = compliance.maxDailyDeposit {
            let todayDeposits = try await fetchTodayDeposits()
            if todayDeposits + amount > maxDaily {
                return ComplianceStatus(
                    isAllowed: false,
                    reason: "Daily deposit limit of \(maxDaily) tokens would be exceeded"
                )
            }
        }
        
        // Check if KYC is required
        if compliance.requiresKYC && amount > 5000 {
            let kycVerified = try await checkKYCStatus()
            if !kycVerified {
                return ComplianceStatus(
                    isAllowed: false,
                    reason: "KYC verification required for deposits over 5000 tokens"
                )
            }
        }
        
        return ComplianceStatus(isAllowed: true, reason: nil)
    }
    
    func checkWithdrawalCompliance(amount: Int) async throws -> ComplianceStatus {
        guard let compliance = currentCompliance else {
            return ComplianceStatus(isAllowed: false, reason: "Compliance not verified")
        }
        
        // Check if KYC is required for withdrawals
        if compliance.requiresKYC {
            let kycVerified = try await checkKYCStatus()
            if !kycVerified {
                return ComplianceStatus(
                    isAllowed: false,
                    reason: "KYC verification required for withdrawals"
                )
            }
        }
        
        // Check withdrawal limits
        let monthlyWithdrawals = try await fetchMonthlyWithdrawals()
        if monthlyWithdrawals > 50000 {
            return ComplianceStatus(
                isAllowed: false,
                reason: "Monthly withdrawal limit reached"
            )
        }
        
        return ComplianceStatus(isAllowed: true, reason: nil)
    }
    
    func checkStakeCompliance(amount: Int) -> ComplianceStatus {
        guard let compliance = currentCompliance else {
            return ComplianceStatus(isAllowed: false, reason: "Compliance not verified")
        }
        
        // Check max single stake
        if let maxStake = compliance.maxSingleStake, amount > maxStake {
            return ComplianceStatus(
                isAllowed: false,
                reason: "Maximum stake of \(maxStake) tokens exceeded"
            )
        }
        
        return ComplianceStatus(isAllowed: true, reason: nil)
    }
    
    func applyRegionalLimits(stake: Int, region: String) -> Int {
        guard let compliance = currentCompliance else { return stake }
        
        if let maxStake = compliance.maxSingleStake {
            return min(stake, maxStake)
        }
        
        return stake
    }
    
    func requiresKYC(for amount: Int, in region: String) -> Bool {
        guard let compliance = currentCompliance else { return false }
        return compliance.requiresKYC && amount > 5000
    }
    
    private func loadComplianceSettings(for region: String) -> ComplianceSettings? {
        // In production, this would fetch from Supabase
        // For now, return mock data
        let settings = ComplianceSettings(
            region: region,
            isAllowed: true,
            ageRequirement: 18,
            maxDailyDeposit: region == "US" ? 10000 : nil,
            maxSingleStake: region == "UK" ? 5000 : nil,
            requiresKYC: ["US", "UK", "Germany"].contains(region)
        )
        return settings
    }
    
    private func fetchTodayDeposits() async throws -> Int {
        // Fetch today's deposits from Supabase
        return 0 // Mock implementation
    }
    
    private func fetchMonthlyWithdrawals() async throws -> Int {
        // Fetch monthly withdrawals from Supabase
        return 0 // Mock implementation
    }
    
    private func checkKYCStatus() async throws -> Bool {
        // Check if user has completed KYC
        return false // Mock implementation
    }
}

struct ComplianceStatus {
    let isAllowed: Bool
    let reason: String?
}

class SecurityManager {
    private let keychain = KeychainManager()
    
    func performSecurityChecks() -> SecurityCheckResult {
        var issues: [SecurityIssue] = []
        
        // Check for jailbreak
        if isJailbroken() {
            issues.append(SecurityIssue(
                type: .jailbreak,
                severity: .high,
                message: "Device appears to be jailbroken"
            ))
        }
        
        // Check for debugger
        if isDebuggerAttached() {
            issues.append(SecurityIssue(
                type: .debugger,
                severity: .medium,
                message: "Debugger detected"
            ))
        }
        
        // Check SSL pinning
        if !isSSLPinningValid() {
            issues.append(SecurityIssue(
                type: .sslPinning,
                severity: .high,
                message: "SSL certificate validation failed"
            ))
        }
        
        return SecurityCheckResult(
            passed: issues.isEmpty,
            issues: issues
        )
    }
    
    private func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        // Check for common jailbreak indicators
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // Check if we can write to system directories
        let testPath = "/private/jailbreak_test.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            // Expected behavior on non-jailbroken devices
        }
        
        return false
        #endif
    }
    
    private func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        
        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        assert(result == 0)
        
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
    
    private func isSSLPinningValid() -> Bool {
        // In production, implement actual SSL pinning validation
        return true
    }
}

struct SecurityCheckResult {
    let passed: Bool
    let issues: [SecurityIssue]
}

struct SecurityIssue {
    enum IssueType {
        case jailbreak
        case debugger
        case sslPinning
        case tampering
    }
    
    enum Severity {
        case low
        case medium
        case high
    }
    
    let type: IssueType
    let severity: Severity
    let message: String
}

// MARK: - KYC Verification

struct KYCVerificationView: View {
    @StateObject private var viewModel = KYCViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "person.text.rectangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        
                        Text("Identity Verification")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("We need to verify your identity to comply with regulations")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 30)
                    
                    // Steps
                    VStack(spacing: 20) {
                        KYCStepRow(
                            step: 1,
                            title: "Personal Information",
                            isCompleted: viewModel.personalInfoCompleted
                        )
                        
                        KYCStepRow(
                            step: 2,
                            title: "Document Upload",
                            isCompleted: viewModel.documentUploaded
                        )
                        
                        KYCStepRow(
                            step: 3,
                            title: "Selfie Verification",
                            isCompleted: viewModel.selfieVerified
                        )
                    }
                    .padding(.horizontal)
                    
                    // Current Step Content
                    Group {
                        switch viewModel.currentStep {
                        case 1:
                            PersonalInfoForm(viewModel: viewModel)
                        case 2:
                            DocumentUploadView(viewModel: viewModel)
                        case 3:
                            SelfieVerificationView(viewModel: viewModel)
                        default:
                            CompletionView()
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("KYC Verification")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .leadingBar) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct KYCStepRow: View {
    let step: Int
    let title: String
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 30, height: 30)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.caption)
                } else {
                    Text("\(step)")
                        .foregroundColor(isCompleted ? .white : .primary)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            
            Text(title)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
}

struct PersonalInfoForm: View {
    @ObservedObject var viewModel: KYCViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            CustomTextField(
                placeholder: "Legal First Name",
                text: $viewModel.firstName,
                icon: "person.fill"
            )
            
            CustomTextField(
                placeholder: "Legal Last Name",
                text: $viewModel.lastName,
                icon: "person.fill"
            )
            
            CustomTextField(
                placeholder: "Date of Birth",
                text: $viewModel.dateOfBirth,
                icon: "calendar"
            )
            
            CustomTextField(
                placeholder: "Social Security Number",
                text: $viewModel.ssn,
                icon: "number"
            )
            
            CustomTextField(
                placeholder: "Address",
                text: $viewModel.address,
                icon: "house.fill"
            )
            
            Button("Continue") {
                viewModel.completePersonalInfo()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!viewModel.isPersonalInfoValid)
        }
    }
}

struct DocumentUploadView: View {
    @ObservedObject var viewModel: KYCViewModel
    @State private var showingDocumentPicker = false
    @State private var selectedDocumentType = DocumentType.driversLicense
    
    enum DocumentType: String, CaseIterable {
        case driversLicense = "Driver's License"
        case passport = "Passport"
        case nationalId = "National ID"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Upload Government ID")
                .font(.headline)
            
            Picker("Document Type", selection: $selectedDocumentType) {
                ForEach(DocumentType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Button {
                showingDocumentPicker = true
            } label: {
                VStack {
                    Image(systemName: "doc.badge.plus")
                        .font(.largeTitle)
                    Text("Upload Document")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            
            if viewModel.documentUploaded {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Document uploaded successfully")
                        .font(.caption)
                }
            }
            
            Button("Continue") {
                viewModel.currentStep = 3
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!viewModel.documentUploaded)
        }
        .sheet(isPresented: $showingDocumentPicker) {
            // Document picker
        }
    }
}

struct SelfieVerificationView: View {
    @ObservedObject var viewModel: KYCViewModel
    @State private var showingCamera = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Take a Selfie")
                .font(.headline)
            
            Text("Please take a clear photo of your face for verification")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingCamera = true
            } label: {
                VStack {
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                    Text("Open Camera")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            
            if viewModel.selfieVerified {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Selfie verified successfully")
                        .font(.caption)
                }
            }
            
            Button("Complete Verification") {
                viewModel.submitKYC()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!viewModel.selfieVerified)
        }
        .sheet(isPresented: $showingCamera) {
            // Camera view
        }
    }
}

struct CompletionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Verification Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Your identity has been verified. You can now access all features.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

class KYCViewModel: ObservableObject {
    @Published var currentStep = 1
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var dateOfBirth = ""
    @Published var ssn = ""
    @Published var address = ""
    @Published var personalInfoCompleted = false
    @Published var documentUploaded = false
    @Published var selfieVerified = false
    
    var isPersonalInfoValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !dateOfBirth.isEmpty &&
        !ssn.isEmpty &&
        !address.isEmpty
    }
    
    func completePersonalInfo() {
        personalInfoCompleted = true
        currentStep = 2
    }
    
    func submitKYC() {
        // Submit KYC data to verification service
        currentStep = 4
    }
}