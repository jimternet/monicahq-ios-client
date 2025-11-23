import Foundation

/// Authentication credentials for Monica API access
struct AuthCredentials {
    let apiURL: String
    let apiToken: String
    let instanceType: InstanceType
    
    enum InstanceType: String, CaseIterable {
        case cloud = "cloud"
        case selfHosted = "self_hosted"
        
        var displayName: String {
            switch self {
            case .cloud:
                return "Monica Cloud"
            case .selfHosted:
                return "Self-Hosted"
            }
        }
        
        var description: String {
            switch self {
            case .cloud:
                return "Use app.monicahq.com"
            case .selfHosted:
                return "Use your own Monica instance"
            }
        }
        
        var defaultURL: String {
            switch self {
            case .cloud:
                return Constants.URLs.monicaCloud
            case .selfHosted:
                return ""
            }
        }
    }
}

/// Authentication state for the app
enum AuthenticationState {
    case unauthenticated
    case authenticating
    case authenticated(AuthCredentials)
    case error(MonicaAPIError)
    
    var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }
    
    var isLoading: Bool {
        if case .authenticating = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .error(let error) = self {
            return error.localizedDescription
        }
        return nil
    }
}

/// Validation result for authentication inputs
struct AuthValidationResult {
    let isValid: Bool
    let urlError: String?
    let tokenError: String?
    
    static let valid = AuthValidationResult(isValid: true, urlError: nil, tokenError: nil)
    
    static func invalid(urlError: String? = nil, tokenError: String? = nil) -> AuthValidationResult {
        return AuthValidationResult(isValid: false, urlError: urlError, tokenError: tokenError)
    }
}