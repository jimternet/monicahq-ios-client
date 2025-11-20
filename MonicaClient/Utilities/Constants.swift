import Foundation

/// Application constants and configuration values
struct Constants {
    
    // MARK: - API Configuration
    struct API {
        static let defaultTimeout: TimeInterval = 30
        static let defaultPerPage = 50
        static let maxRetryAttempts = 3
        static let retryDelay: TimeInterval = 1.0
        
        struct Endpoints {
            static let me = "/me"
            static let contacts = "/contacts"
            static let activities = "/activities"
            static let notes = "/notes"
            static let tasks = "/tasks"
            static let gifts = "/gifts"
            static let tags = "/tags"
        }
        
        struct Headers {
            static let authorization = "Authorization"
            static let contentType = "Content-Type"
            static let accept = "Accept"
            static let userAgent = "User-Agent"
        }
        
        struct ContentTypes {
            static let json = "application/json"
            static let formData = "application/x-www-form-urlencoded"
        }
    }
    
    // MARK: - App Configuration
    struct App {
        static let name = "Monica Client"
        static let bundleId = "com.monicahq.client"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        static let userAgent = "\(name)/\(version) (\(build))"
    }
    
    // MARK: - UI Configuration
    struct UI {
        static let searchDebounceTime: TimeInterval = 0.3
        static let animationDuration: TimeInterval = 0.25
        static let refreshThreshold: TimeInterval = 300 // 5 minutes

        struct Spacing {
            static let extraSmall: CGFloat = 4
            static let small: CGFloat = 8
            static let medium: CGFloat = 16
            static let large: CGFloat = 24
            static let extraLarge: CGFloat = 32
        }

        struct CornerRadius {
            static let small: CGFloat = 4
            static let medium: CGFloat = 8
            static let large: CGFloat = 12
        }

        struct Images {
            static let defaultContactSize: CGFloat = 40
            static let largeContactSize: CGFloat = 80
        }

        struct Animation {
            static let fastDuration: TimeInterval = 0.2
            static let defaultDuration: TimeInterval = 0.3
            static let slowDuration: TimeInterval = 0.5
        }
    }

    // MARK: - Cache Configuration
    struct Cache {
        static let defaultTTL: TimeInterval = 300 // 5 minutes
        static let maxMemoryUsage = 50 * 1024 * 1024 // 50MB
        static let cleanupInterval: TimeInterval = 600 // 10 minutes
    }

    // MARK: - Pagination
    struct Pagination {
        static let defaultPageSize = 50
        static let maxPageSize = 100
        static let prefetchThreshold = 10 // Load more when 10 items from end
    }
    
    // MARK: - URLs
    struct URLs {
        static let monicaCloud = "https://app.monicahq.com"
        static let documentation = "https://docs.monicahq.com"
        static let support = "https://github.com/monicahq/monica/discussions"
        static let privacyPolicy = "https://www.monicahq.com/privacy"
        static let termsOfService = "https://www.monicahq.com/terms"
    }
    
    // MARK: - Keychain
    struct Keychain {
        static let service = "com.monicahq.client"
        static let accessGroup: String? = nil // Use nil for single app
    }
    
    // MARK: - Error Messages
    struct ErrorMessages {
        static let genericError = "Something went wrong. Please try again."
        static let networkError = "Please check your internet connection and try again."
        static let authenticationError = "Please check your API token and try again."
        static let serverError = "The server is experiencing issues. Please try again later."
        static let noDataError = "No data available."
        static let invalidURLError = "Invalid URL format."
    }
    
    // MARK: - Feature Flags
    struct FeatureFlags {
        static let enablePushNotifications = false
        static let enableOfflineMode = true
        static let enableAnalytics = false
        static let enableDebugLogging = true
    }
    
    // MARK: - Date Formats
    struct DateFormats {
        static let iso8601 = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        static let display = "MMM d, yyyy"
        static let displayWithTime = "MMM d, yyyy 'at' h:mm a"
        static let relative = "relative"
    }
}