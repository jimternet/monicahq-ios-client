import Foundation

/// Enhanced API client extension with retry logic and comprehensive error handling
extension MonicaAPIClient {
    
    /// Maximum number of retry attempts for retryable errors
    private var maxRetryAttempts: Int { 3 }
    
    /// Initial retry delay in seconds
    private var initialRetryDelay: TimeInterval { 1.0 }
    
    /// Executes a request with automatic retry logic
    func executeWithRetry<T>(
        operation: @escaping () async throws -> T,
        retryCount: Int = 0
    ) async throws -> T {
        do {
            // Check network connectivity before making request
            guard NetworkMonitor.shared.checkConnectivity() else {
                throw MonicaAPIError.networkError(NSError(
                    domain: "NetworkMonitor",
                    code: -1009,
                    userInfo: [NSLocalizedDescriptionKey: "No internet connection"]
                ))
            }
            
            return try await operation()
            
        } catch let error as MonicaAPIError {
            // Handle specific error cases
            switch error {
            case .unauthorized:
                // Clear credentials and notify authentication manager
                await handleUnauthorized()
                throw error
                
            case .rateLimited:
                // Implement exponential backoff for rate limiting
                if retryCount < maxRetryAttempts {
                    let delay = initialRetryDelay * pow(2, Double(retryCount))
                    print("⏳ Rate limited. Retrying in \(delay) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await executeWithRetry(
                        operation: operation,
                        retryCount: retryCount + 1
                    )
                }
                throw error
                
            case .networkError, .serverError:
                // Retry network and server errors with exponential backoff
                if error.isRetryable && retryCount < maxRetryAttempts {
                    let delay = initialRetryDelay * pow(2, Double(retryCount))
                    print("🔄 Retrying after error: \(error.localizedDescription)")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await executeWithRetry(
                        operation: operation,
                        retryCount: retryCount + 1
                    )
                }
                throw error
                
            default:
                throw error
            }
        }
    }
    
    /// Handles unauthorized errors by clearing credentials
    @MainActor
    private func handleUnauthorized() async {
        print("⚠️ Handling unauthorized error - clearing credentials")
        // This would typically trigger a logout through the authentication manager
        NotificationCenter.default.post(
            name: Notification.Name("MonicaAPIUnauthorized"),
            object: nil
        )
    }
    
    /// Logs errors for debugging without exposing PII
    func logError(_ error: Error, context: String) {
        let sanitizedError = sanitizeErrorForLogging(error)
        print("❌ API Error in \(context): \(sanitizedError)")
        
        // Log to analytics service (without PII)
        #if DEBUG
        print("📊 Debug info: \(error)")
        #endif
    }
    
    /// Sanitizes error messages to remove any PII
    private func sanitizeErrorForLogging(_ error: Error) -> String {
        var message = error.localizedDescription
        
        // Remove potential email addresses
        message = message.replacingOccurrences(
            of: "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}",
            with: "[EMAIL]",
            options: .regularExpression
        )
        
        // Remove potential API tokens (long alphanumeric strings)
        message = message.replacingOccurrences(
            of: "[A-Za-z0-9]{32,}",
            with: "[TOKEN]",
            options: .regularExpression
        )
        
        // Remove potential URLs with user data
        message = message.replacingOccurrences(
            of: "https?://[^\\s]+",
            with: "[URL]",
            options: .regularExpression
        )
        
        return message
    }
}

/// Error recovery helper
struct ErrorRecoveryHelper {
    
    /// Determines if an error should trigger a retry
    static func shouldRetry(for error: Error) -> Bool {
        guard let apiError = error as? MonicaAPIError else {
            return false
        }
        return apiError.isRetryable
    }
    
    /// Provides user-friendly error messages with recovery suggestions
    static func userMessage(for error: Error) -> (title: String, message: String, suggestion: String?) {
        if let apiError = error as? MonicaAPIError {
            let title = "Connection Error"
            let message = apiError.errorDescription ?? "An unexpected error occurred"
            let suggestion = apiError.recoverySuggestion
            return (title, message, suggestion)
        }
        
        // Generic error handling
        return (
            "Error",
            error.localizedDescription,
            "Please try again or contact support if the problem persists."
        )
    }
    
    /// Creates an alert configuration for an error
    static func alertConfiguration(for error: Error, retryAction: (() -> Void)? = nil) -> AlertConfiguration {
        let (title, message, suggestion) = userMessage(for: error)
        let fullMessage = suggestion != nil ? "\(message)\n\n\(suggestion!)" : message
        
        var actions: [AlertAction] = []
        
        if let retry = retryAction, shouldRetry(for: error) {
            actions.append(AlertAction(title: "Retry", style: .default, handler: retry))
        }
        
        actions.append(AlertAction(title: "OK", style: .cancel, handler: nil))
        
        return AlertConfiguration(
            title: title,
            message: fullMessage,
            actions: actions
        )
    }
}

/// Alert configuration for error presentation
struct AlertConfiguration {
    let title: String
    let message: String
    let actions: [AlertAction]
}

struct AlertAction {
    let title: String
    let style: Style
    let handler: (() -> Void)?
    
    enum Style {
        case `default`
        case cancel
        case destructive
    }
}