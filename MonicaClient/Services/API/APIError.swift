import Foundation

/// Comprehensive error handling for Monica API operations
enum MonicaAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int)
    case decodingError(DecodingError)
    case networkError(Error)
    case rateLimited
    case badRequest(String)
    case noData
    case invalidCredentials
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL format"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Authentication failed. Please check your API token."
        case .forbidden:
            return "Access denied. Your API token may not have sufficient permissions."
        case .notFound:
            return "The requested resource was not found"
        case .serverError(let code):
            return "Server error (HTTP \(code)). Please try again later."
        case .decodingError:
            return "Failed to process server response"
        case .networkError(let error):
            return "Network connection failed: \(error.localizedDescription)"
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .badRequest(let message):
            return "Invalid request: \(message)"
        case .noData:
            return "No data received from server"
        case .invalidCredentials:
            return "Invalid API endpoint or token. Please check your configuration."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .unauthorized, .invalidCredentials:
            return "Please check your API token in settings and try again."
        case .networkError:
            return "Check your internet connection and try again."
        case .serverError:
            return "The server is experiencing issues. Please try again later."
        case .rateLimited:
            return "Please wait a moment before making another request."
        default:
            return "Please try again or contact support if the problem persists."
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkError, .serverError, .rateLimited:
            return true
        case .unauthorized, .forbidden, .invalidURL, .invalidCredentials, .badRequest:
            return false
        default:
            return false
        }
    }
}