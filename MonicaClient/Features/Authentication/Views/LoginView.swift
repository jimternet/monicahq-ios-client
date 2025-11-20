import SwiftUI

/// Login view for API endpoint and token configuration
struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var apiURL: String = ""
    @State private var apiToken: String = ""
    @State private var showPassword: Bool = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case url, token
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.UI.Spacing.large) {
                    // Header
                    VStack(spacing: Constants.UI.Spacing.medium) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.monicaBlue)
                        
                        Text("Connect to Monica")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Enter your API details to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Constants.UI.Spacing.large)
                    
                    // Form
                    VStack(spacing: Constants.UI.Spacing.medium) {
                        // Instance Type Display
                        if let instanceType = authViewModel.selectedInstanceType {
                            HStack {
                                Image(systemName: instanceType == .cloud ? "cloud.fill" : "server.rack")
                                    .foregroundColor(.monicaBlue)
                                Text(instanceType.displayName)
                                    .fontWeight(.medium)
                                Spacer()
                                Button("Change") {
                                    authViewModel.showLogin = false
                                }
                                .font(.caption)
                                .foregroundColor(.monicaBlue)
                            }
                            .padding(Constants.UI.Spacing.medium)
                            .background(Color.secondaryBackground)
                            .cornerRadius(Constants.UI.CornerRadius.medium)
                        }
                        
                        // API URL Field
                        VStack(alignment: .leading, spacing: Constants.UI.Spacing.small) {
                            Text("API URL")
                                .font(.headline)
                            
                            TextField("https://app.monicahq.com", text: $apiURL)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .keyboardType(.URL)
                                .focused($focusedField, equals: .url)
                                .onSubmit {
                                    focusedField = .token
                                }
                            
                            if let error = authViewModel.validationResult?.urlError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.errorRed)
                            }
                        }
                        
                        // API Token Field
                        VStack(alignment: .leading, spacing: Constants.UI.Spacing.small) {
                            HStack {
                                Text("API Token")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button("Get Token") {
                                    openTokenHelp()
                                }
                                .font(.caption)
                                .foregroundColor(.monicaBlue)
                            }
                            
                            HStack {
                                Group {
                                    if showPassword {
                                        TextField("Enter your API token", text: $apiToken)
                                    } else {
                                        SecureField("Enter your API token", text: $apiToken)
                                    }
                                }
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .focused($focusedField, equals: .token)
                                .onSubmit {
                                    authenticateUser()
                                }
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.secondaryText)
                                }
                            }
                            
                            if let error = authViewModel.validationResult?.tokenError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.errorRed)
                            }
                        }
                        
                        // Help Text
                        Text("Your API token is used to securely connect to your Monica instance. It's stored securely in your device's Keychain.")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(Constants.UI.Spacing.medium)
                    
                    // Error Display
                    if let errorMessage = authViewModel.authState.errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.errorRed)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.errorRed.opacity(0.1))
                            .cornerRadius(Constants.UI.CornerRadius.medium)
                    }
                    
                    // Login Button
                    Button(action: authenticateUser) {
                        HStack {
                            if authViewModel.authState.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Connecting...")
                            } else {
                                Text("Connect")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            authViewModel.canAttemptLogin(url: apiURL, token: apiToken) ? 
                            Color.monicaBlue : Color.gray
                        )
                        .foregroundColor(.white)
                        .cornerRadius(Constants.UI.CornerRadius.medium)
                    }
                    .disabled(!authViewModel.canAttemptLogin(url: apiURL, token: apiToken) || authViewModel.authState.isLoading)
                    
                    Spacer()
                }
                .padding(Constants.UI.Spacing.large)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        authViewModel.showLogin = false
                    }
                }
            }
        }
        .onAppear {
            setupInitialValues()
        }
        .hideKeyboardOnTap()
    }
    
    private func setupInitialValues() {
        if let instanceType = authViewModel.selectedInstanceType {
            apiURL = instanceType.defaultURL
        }
    }
    
    private func authenticateUser() {
        Task {
            await authViewModel.authenticate(apiURL: apiURL, apiToken: apiToken)
        }
    }
    
    private func openTokenHelp() {
        let baseURL = apiURL.isEmpty ? Constants.URLs.monicaCloud : apiURL
        let tokenURL = "\(baseURL)/settings/api"
        
        if let url = URL(string: tokenURL) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview("Login - Cloud") {
    LoginView()
        .environmentObject({
            let vm = AuthenticationViewModel()
            vm.selectedInstanceType = .cloud
            vm.showLogin = true
            return vm
        }())
}

#Preview("Login - Self Hosted") {
    LoginView()
        .environmentObject({
            let vm = AuthenticationViewModel()
            vm.selectedInstanceType = .selfHosted
            vm.showLogin = true
            return vm
        }())
}

#Preview("Login - Loading") {
    LoginView()
        .environmentObject({
            let vm = AuthenticationViewModel()
            vm.selectedInstanceType = .cloud
            vm.showLogin = true
            vm.authState = .authenticating
            return vm
        }())
}