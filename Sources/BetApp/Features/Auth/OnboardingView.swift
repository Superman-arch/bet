import SwiftUI
import CoreLocation

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                TabView(selection: $viewModel.currentPage) {
                    WelcomeView()
                        .tag(0)
                    
                    AgeVerificationView(viewModel: viewModel)
                        .tag(1)
                    
                    RegionSelectionView(viewModel: viewModel)
                        .tag(2)
                    
                    AccountSetupView(viewModel: viewModel)
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentPage)
                
                HStack {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(index == viewModel.currentPage ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: viewModel.currentPage)
                    }
                }
                .padding(.bottom, 20)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.accentColor)
                .symbolEffect(.bounce, value: true)
            
            VStack(spacing: 10) {
                Text("Welcome to Bet")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Social wagering with friends")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(icon: "person.2.fill", title: "Compete with Friends", description: "Challenge friends in skill-based activities")
                FeatureRow(icon: "trophy.fill", title: "Win Tokens", description: "Earn virtual tokens and cash out anytime")
                FeatureRow(icon: "shield.checkered", title: "Safe & Secure", description: "Regulated platform with secure payments")
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            Button("Get Started") {
                withAnimation {
                    OnboardingViewModel.shared.currentPage = 1
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct AgeVerificationView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var selectedDate = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    
    var age: Int {
        Calendar.current.dateComponents([.year], from: selectedDate, to: Date()).year ?? 0
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "person.text.rectangle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            VStack(spacing: 10) {
                Text("Verify Your Age")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("You must be 18 or older to use Bet")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            DatePicker("Birthday", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .padding(.horizontal, 40)
            
            if age < 18 {
                Text("You must be at least 18 years old")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Spacer()
            
            Button("Continue") {
                if age >= 18 {
                    viewModel.age = age
                    withAnimation {
                        viewModel.currentPage = 2
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(age < 18)
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
    }
}

struct RegionSelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @StateObject private var locationManager = LocationManager()
    
    let availableRegions = [
        "United States",
        "Canada",
        "United Kingdom",
        "Australia",
        "Germany",
        "France",
        "Spain",
        "Italy",
        "Netherlands",
        "Sweden",
        "Norway",
        "Denmark"
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "globe.americas.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            VStack(spacing: 10) {
                Text("Select Your Region")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("We need to verify you're in a supported region")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(availableRegions, id: \.self) { region in
                        Button {
                            viewModel.selectedRegion = region
                        } label: {
                            HStack {
                                Text(region)
                                    .foregroundColor(.primary)
                                Spacer()
                                if viewModel.selectedRegion == region {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
            .frame(maxHeight: 300)
            
            Button {
                Task {
                    await locationManager.requestLocation()
                    if let region = locationManager.detectedRegion {
                        viewModel.selectedRegion = region
                    }
                }
            } label: {
                Label("Detect Automatically", systemImage: "location.fill")
                    .font(.caption)
            }
            
            Spacer()
            
            Button("Continue") {
                if viewModel.selectedRegion != nil {
                    withAnimation {
                        viewModel.currentPage = 3
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.selectedRegion == nil)
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
    }
}

struct AccountSetupView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .padding(.top, 60)
            
            Text("Create Your Account")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                CustomTextField(
                    placeholder: "Username",
                    text: $viewModel.username,
                    icon: "person.fill"
                )
                
                CustomTextField(
                    placeholder: "Email",
                    text: $viewModel.email,
                    icon: "envelope.fill",
                    keyboardType: .emailAddress
                )
                
                CustomTextField(
                    placeholder: "Phone (Optional)",
                    text: $viewModel.phone,
                    icon: "phone.fill",
                    keyboardType: .phonePad
                )
                
                CustomSecureField(
                    placeholder: "Password",
                    text: $viewModel.password,
                    icon: "lock.fill"
                )
                
                CustomSecureField(
                    placeholder: "Confirm Password",
                    text: $viewModel.confirmPassword,
                    icon: "lock.fill"
                )
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            VStack(spacing: 15) {
                Button("Create Account") {
                    Task {
                        await viewModel.createAccount(authManager: authManager)
                        if authManager.isAuthenticated {
                            dismiss()
                        }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!viewModel.isValid)
                
                Button("Already have an account? Sign In") {
                    dismiss()
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
    }
}

class OnboardingViewModel: ObservableObject {
    static let shared = OnboardingViewModel()
    
    @Published var currentPage = 0
    @Published var age = 0
    @Published var selectedRegion: String?
    @Published var username = ""
    @Published var email = ""
    @Published var phone = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var showError = false
    @Published var errorMessage = ""
    
    var isValid: Bool {
        !username.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        password.count >= 8 &&
        password == confirmPassword
    }
    
    func createAccount(authManager: AuthManager) async {
        do {
            try await authManager.signUp(
                email: email,
                password: password,
                username: username,
                phone: phone.isEmpty ? nil : phone,
                region: selectedRegion ?? "Unknown",
                age: age
            )
            
            UserDefaults.standard.set(true, forKey: Environment.UserDefaultsKeys.hasCompletedOnboarding)
            UserDefaults.standard.set(true, forKey: Environment.UserDefaultsKeys.ageVerified)
            UserDefaults.standard.set(selectedRegion, forKey: Environment.UserDefaultsKeys.userRegion)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var detectedRegion: String?
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func requestLocation() async {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let country = placemarks?.first?.country {
                self.detectedRegion = country
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}