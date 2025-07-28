import SwiftUI

struct SignInView: View {
    @StateObject private var viewModel = SignInViewModel()
    @EnvironmentObject var authManager: AuthManager
    @State private var showingSignUp = false
    @State private var showingForgotPassword = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Logo and Title
                    VStack(spacing: 20) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.accentColor)
                            .symbolEffect(.bounce, value: viewModel.loginAttempts)
                        
                        Text("Welcome Back")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 60)
                    
                    // Sign In Form
                    VStack(spacing: 15) {
                        CustomTextField(
                            placeholder: "Email",
                            text: $viewModel.email,
                            icon: "envelope.fill",
                            keyboardType: .emailAddress
                        )
                        
                        CustomSecureField(
                            placeholder: "Password",
                            text: $viewModel.password,
                            icon: "lock.fill"
                        )
                        
                        HStack {
                            Toggle("Remember me", isOn: $viewModel.rememberMe)
                                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                                .font(.caption)
                            
                            Spacer()
                            
                            Button("Forgot Password?") {
                                showingForgotPassword = true
                            }
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    // Sign In Button
                    VStack(spacing: 15) {
                        Button {
                            Task {
                                await viewModel.signIn(authManager: authManager)
                            }
                        } label: {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(viewModel.isLoading || !viewModel.isValid)
                        
                        // Biometric Sign In
                        if viewModel.biometricAvailable {
                            Button {
                                Task {
                                    await viewModel.signInWithBiometrics(authManager: authManager)
                                }
                            } label: {
                                Label("Sign in with Face ID", systemImage: "faceid")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        
                        Text("OR")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 40)
                    
                    // Sign Up Link
                    VStack(spacing: 10) {
                        Text("Don't have an account?")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Create Account") {
                            showingSignUp = true
                        }
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    }
                    
                    Spacer(minLength: 50)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $showingSignUp) {
                OnboardingView()
            }
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
        }
    }
}

class SignInViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var rememberMe = true
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var loginAttempts = 0
    
    var biometricAvailable: Bool {
        // Check if biometric authentication is available
        return false // Implement actual check
    }
    
    var isValid: Bool {
        !email.isEmpty && email.contains("@") && !password.isEmpty
    }
    
    func signIn(authManager: AuthManager) async {
        isLoading = true
        loginAttempts += 1
        defer { isLoading = false }
        
        do {
            try await authManager.signIn(email: email, password: password)
            HapticManager.success()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            HapticManager.error()
        }
    }
    
    func signInWithBiometrics(authManager: AuthManager) async {
        let authenticated = await authManager.authenticateWithBiometrics()
        if authenticated {
            // Retrieve saved credentials and sign in
            HapticManager.success()
        } else {
            HapticManager.error()
        }
    }
}

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "key.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                    .padding(.top, 40)
                
                VStack(spacing: 10) {
                    Text("Reset Password")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Enter your email and we'll send you a reset link")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                CustomTextField(
                    placeholder: "Email",
                    text: $email,
                    icon: "envelope.fill",
                    keyboardType: .emailAddress
                )
                .padding(.horizontal, 40)
                
                Spacer()
                
                Button {
                    Task {
                        await sendResetLink()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Send Reset Link")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(email.isEmpty || !email.contains("@"))
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Check Your Email", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("We've sent a password reset link to \(email)")
            }
        }
    }
    
    private func sendResetLink() async {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        showSuccess = true
        HapticManager.success()
    }
}