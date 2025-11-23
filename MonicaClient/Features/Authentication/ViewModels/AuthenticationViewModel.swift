import Foundation
import SwiftUI

/// ViewModel for authentication flow and state management
@MainActor
class AuthenticationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var authState: AuthenticationState = .unauthenticated
    @Published var selectedInstanceType: AuthCredentials.InstanceType?
    @Published var showLogin: Bool = false
    @Published var validationResult: AuthValidationResult?
    
    // MARK: - Dependencies
    private let keychainService: KeychainService
    private let userDefaultsService: UserDefaultsService
    private let cacheService: CacheService
    private var apiClient: MonicaAPIClientProtocol?
    
    // MARK: - Initialization
    init(
        keychainService: KeychainService = KeychainService(),
        userDefaultsService: UserDefaultsService = UserDefaultsService(),
        cacheService: CacheService = CacheService()
    ) {
        self.keychainService = keychainService
        self.userDefaultsService = userDefaultsService
        self.cacheService = cacheService
        
        Task {
            await checkExistingAuthentication()
        }
    }
    
    // MARK: - Public Methods
    
    /// Check if user has existing valid authentication
    func checkExistingAuthentication() async {
        guard keychainService.hasStoredCredentials() else {
            authState = .unauthenticated
            return
        }
        
        do {
            let apiURL = try keychainService.retrieve(for: .apiURL)
            let apiToken = try keychainService.retrieve(for: .apiToken)
            
            authState = .authenticating
            
            let client = MonicaAPIClient(baseURL: apiURL, apiToken: apiToken, cacheService: cacheService)
            try await client.testConnection()
            
            let credentials = AuthCredentials(
                apiURL: apiURL,
                apiToken: apiToken,
                instanceType: determineInstanceType(from: apiURL)
            )
            
            self.apiClient = client
            authState = .authenticated(credentials)
            
        } catch {
            // Clear invalid credentials
            keychainService.deleteAllCredentials()
            authState = .unauthenticated
        }
    }
    
    /// Authenticate user with provided credentials
    func authenticate(apiURL: String, apiToken: String) async {
        let validation = validateCredentials(apiURL: apiURL, apiToken: apiToken)
        validationResult = validation
        
        guard validation.isValid else {
            return
        }
        
        authState = .authenticating
        
        do {
            let client = MonicaAPIClient(baseURL: apiURL, apiToken: apiToken, cacheService: cacheService)
            try await client.testConnection()
            
            // Store credentials securely
            try keychainService.store(apiURL, for: .apiURL)
            try keychainService.store(apiToken, for: .apiToken)
            
            // Update app settings
            userDefaultsService.onboardingCompleted = true
            userDefaultsService.lastSyncDate = Date()
            
            let credentials = AuthCredentials(
                apiURL: apiURL,
                apiToken: apiToken,
                instanceType: selectedInstanceType ?? determineInstanceType(from: apiURL)
            )
            
            self.apiClient = client
            authState = .authenticated(credentials)
            showLogin = false
            validationResult = nil
            
        } catch let error as MonicaAPIError {
            authState = .error(error)
        } catch {
            authState = .error(MonicaAPIError.networkError(error))
        }
    }
    
    /// Log out user and clear stored data
    func logout() {
        keychainService.deleteAllCredentials()
        cacheService.clearAllCache()
        
        selectedInstanceType = nil
        showLogin = false
        validationResult = nil
        apiClient = nil
        authState = .unauthenticated
        
        userDefaultsService.lastSyncDate = nil
    }
    
    /// Switch to different Monica instance
    func switchInstance() {
        logout()
    }
    
    /// Retry authentication with stored credentials
    func retryAuthentication() async {
        await checkExistingAuthentication()
    }
    
    /// Check if login attempt can be made with current inputs
    func canAttemptLogin(url: String, token: String) -> Bool {
        return !url.trimmed.isEmpty && !token.trimmed.isEmpty && !authState.isLoading
    }
    
    /// Get current API client
    func getAPIClient() -> MonicaAPIClientProtocol? {
        return apiClient
    }
    
    // MARK: - Private Methods
    
    private func validateCredentials(apiURL: String, apiToken: String) -> AuthValidationResult {
        var urlError: String?
        var tokenError: String?
        
        // Validate URL
        let trimmedURL = apiURL.trimmed
        if trimmedURL.isEmpty {
            urlError = "API URL is required"
        } else if !trimmedURL.isValidURL {
            urlError = "Please enter a valid URL"
        } else if !trimmedURL.hasPrefix("https://") {
            urlError = "URL must use HTTPS for security"
        }
        
        // Validate Token
        let trimmedToken = apiToken.trimmed
        if trimmedToken.isEmpty {
            tokenError = "API Token is required"
        } else if trimmedToken.count < 20 {
            tokenError = "API Token appears to be too short"
        }
        
        if urlError != nil || tokenError != nil {
            return AuthValidationResult.invalid(urlError: urlError, tokenError: tokenError)
        }
        
        return AuthValidationResult.valid
    }
    
    private func determineInstanceType(from url: String) -> AuthCredentials.InstanceType {
        if url.contains("app.monicahq.com") {
            return .cloud
        } else {
            return .selfHosted
        }
    }
}

// MARK: - Computed Properties
extension AuthenticationViewModel {
    
    var isAuthenticated: Bool {
        authState.isAuthenticated
    }
    
    var isLoading: Bool {
        authState.isLoading
    }
    
    var currentCredentials: AuthCredentials? {
        if case .authenticated(let credentials) = authState {
            return credentials
        }
        return nil
    }
    
    var shouldShowOnboarding: Bool {
        !userDefaultsService.onboardingCompleted && !isAuthenticated
    }
}