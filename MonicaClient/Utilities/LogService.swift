//
//  LogService.swift
//  MonicaClient
//
//  Created by SpecKit Implementation
//  Copyright © 2025 Monica Client. All rights reserved.
//

import Foundation
import OSLog

/// Centralized logging service for the Monica iOS Client
/// Uses Apple's OSLog framework for structured, performant logging
/// Automatically redacts PII to protect user privacy
final class LogService {

    // MARK: - Singleton

    static let shared = LogService()

    // MARK: - Properties

    private let subsystem = Bundle.main.bundleIdentifier ?? "com.monica.client"

    /// Logger instances for different categories
    private lazy var generalLogger = Logger(subsystem: subsystem, category: "general")
    private lazy var networkLogger = Logger(subsystem: subsystem, category: "network")
    private lazy var authLogger = Logger(subsystem: subsystem, category: "authentication")
    private lazy var storageLogger = Logger(subsystem: subsystem, category: "storage")
    private lazy var performanceLogger = Logger(subsystem: subsystem, category: "performance")

    // MARK: - Initialization

    private init() {
        // Private initializer for singleton
    }

    // MARK: - Log Levels

    enum LogLevel {
        case debug
        case info
        case warning
        case error
        case critical

        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }

        var prefix: String {
            switch self {
            case .debug: return "🔍 DEBUG"
            case .info: return "ℹ️ INFO"
            case .warning: return "⚠️ WARNING"
            case .error: return "❌ ERROR"
            case .critical: return "🔥 CRITICAL"
            }
        }
    }

    // MARK: - Log Categories

    enum Category {
        case general
        case network
        case authentication
        case storage
        case performance

        var description: String {
            switch self {
            case .general: return "GENERAL"
            case .network: return "NETWORK"
            case .authentication: return "AUTH"
            case .storage: return "STORAGE"
            case .performance: return "PERF"
            }
        }
    }

    // MARK: - Public Logging Methods

    /// Log a message with specified level and category
    /// - Parameters:
    ///   - message: The message to log
    ///   - level: Log level (default: .info)
    ///   - category: Log category (default: .general)
    ///   - redactPII: Whether to redact potentially sensitive information (default: true)
    func log(
        _ message: String,
        level: LogLevel = .info,
        category: Category = .general,
        redactPII: Bool = true
    ) {
        let logger = self.logger(for: category)
        let privacy: OSLogPrivacy = redactPII ? .private : .public

        logger.log(
            level: level.osLogType,
            "[\(category.description, privacy: .public)] \(level.prefix, privacy: .public) \(message, privacy: privacy)"
        )
    }

    // MARK: - Convenience Methods by Level

    /// Log debug information (development only)
    func debug(_ message: String, category: Category = .general) {
        #if DEBUG
        log(message, level: .debug, category: category, redactPII: false)
        #endif
    }

    /// Log informational message
    func info(_ message: String, category: Category = .general) {
        log(message, level: .info, category: category)
    }

    /// Log warning message
    func warning(_ message: String, category: Category = .general) {
        log(message, level: .warning, category: category)
    }

    /// Log error message
    func error(_ message: String, category: Category = .general, error: Error? = nil) {
        var fullMessage = message
        if let error = error {
            fullMessage += " - \(error.localizedDescription)"
        }
        log(fullMessage, level: .error, category: category, redactPII: false)
    }

    /// Log critical error (requires immediate attention)
    func critical(_ message: String, category: Category = .general, error: Error? = nil) {
        var fullMessage = message
        if let error = error {
            fullMessage += " - \(error.localizedDescription)"
        }
        log(fullMessage, level: .critical, category: category, redactPII: false)
    }

    // MARK: - Convenience Methods by Category

    /// Log network-related event
    func network(_ message: String, level: LogLevel = .info) {
        log(message, level: level, category: .network)
    }

    /// Log authentication-related event
    func auth(_ message: String, level: LogLevel = .info) {
        log(message, level: level, category: .authentication)
    }

    /// Log storage-related event
    func storage(_ message: String, level: LogLevel = .info) {
        log(message, level: level, category: .storage)
    }

    /// Log performance-related event
    func performance(_ message: String, level: LogLevel = .info) {
        log(message, level: level, category: .performance)
    }

    // MARK: - Performance Measurement

    /// Measure and log execution time of an operation
    /// - Parameters:
    ///   - operation: Name of the operation
    ///   - category: Log category
    ///   - block: The operation to measure
    /// - Returns: Result of the operation
    @discardableResult
    func measure<T>(
        _ operation: String,
        category: Category = .performance,
        block: () throws -> T
    ) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let elapsed = CFAbsoluteTimeGetCurrent() - start
            let elapsedMs = String(format: "%.2f", elapsed * 1000)
            performance("\(operation) completed in \(elapsedMs)ms", level: .info)
        }
        return try block()
    }

    /// Measure and log execution time of an async operation
    /// - Parameters:
    ///   - operation: Name of the operation
    ///   - category: Log category
    ///   - block: The async operation to measure
    /// - Returns: Result of the operation
    @discardableResult
    func measureAsync<T>(
        _ operation: String,
        category: Category = .performance,
        block: () async throws -> T
    ) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let elapsed = CFAbsoluteTimeGetCurrent() - start
            let elapsedMs = String(format: "%.2f", elapsed * 1000)
            performance("\(operation) completed in \(elapsedMs)ms", level: .info)
        }
        return try await block()
    }

    // MARK: - Helper Methods

    private func logger(for category: Category) -> Logger {
        switch category {
        case .general: return generalLogger
        case .network: return networkLogger
        case .authentication: return authLogger
        case .storage: return storageLogger
        case .performance: return performanceLogger
        }
    }
}

// MARK: - API Request/Response Logging Extensions

extension LogService {

    /// Log API request details
    /// - Parameters:
    ///   - method: HTTP method (GET, POST, etc.)
    ///   - endpoint: API endpoint path
    ///   - parameters: Query parameters or request body (will be redacted)
    func logAPIRequest(method: String, endpoint: String, parameters: [String: Any]? = nil) {
        var message = "API Request: \(method) \(endpoint)"
        if let params = parameters, !params.isEmpty {
            message += " with \(params.count) parameters"
        }
        network(message, level: .info)
    }

    /// Log API response details
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - statusCode: HTTP status code
    ///   - duration: Request duration in milliseconds
    func logAPIResponse(endpoint: String, statusCode: Int, duration: TimeInterval) {
        let durationMs = String(format: "%.2f", duration * 1000)
        let statusEmoji: String
        switch statusCode {
        case 200..<300: statusEmoji = "✅"
        case 300..<400: statusEmoji = "↩️"
        case 400..<500: statusEmoji = "⚠️"
        default: statusEmoji = "❌"
        }

        network("\(statusEmoji) API Response: \(endpoint) - Status: \(statusCode) - Duration: \(durationMs)ms", level: .info)
    }

    /// Log API error
    /// - Parameters:
    ///   - endpoint: API endpoint path
    ///   - error: The error that occurred
    ///   - statusCode: HTTP status code (if available)
    func logAPIError(endpoint: String, error: Error, statusCode: Int? = nil) {
        var message = "API Error: \(endpoint) - \(error.localizedDescription)"
        if let code = statusCode {
            message += " (HTTP \(code))"
        }
        network(message, level: .error)
    }
}

// MARK: - Authentication Logging Extensions

extension LogService {

    /// Log authentication attempt
    /// - Parameter instanceType: "cloud" or "self-hosted"
    func logAuthAttempt(instanceType: String) {
        auth("Authentication attempt started for \(instanceType) instance", level: .info)
    }

    /// Log successful authentication
    func logAuthSuccess() {
        auth("Authentication successful", level: .info)
    }

    /// Log authentication failure
    /// - Parameter reason: Failure reason (will be redacted if contains PII)
    func logAuthFailure(reason: String) {
        auth("Authentication failed: \(reason)", level: .error)
    }

    /// Log logout event
    func logLogout() {
        auth("User logged out", level: .info)
    }
}

// MARK: - Storage Logging Extensions

extension LogService {

    /// Log Keychain operation
    /// - Parameters:
    ///   - operation: Operation name (save, retrieve, delete)
    ///   - success: Whether operation succeeded
    func logKeychainOperation(_ operation: String, success: Bool) {
        let message = "Keychain \(operation): \(success ? "✅ Success" : "❌ Failed")"
        storage(message, level: success ? .info : .error)
    }

    /// Log cache operation
    /// - Parameters:
    ///   - operation: Operation name (store, retrieve, clear)
    ///   - itemCount: Number of items affected
    func logCacheOperation(_ operation: String, itemCount: Int) {
        storage("Cache \(operation): \(itemCount) items", level: .info)
    }
}

// MARK: - View Lifecycle Logging Extensions

extension LogService {

    /// Log view appearance
    /// - Parameter viewName: Name of the view
    func logViewAppeared(_ viewName: String) {
        debug("View appeared: \(viewName)", category: .general)
    }

    /// Log view disappearance
    /// - Parameter viewName: Name of the view
    func logViewDisappeared(_ viewName: String) {
        debug("View disappeared: \(viewName)", category: .general)
    }
}

// MARK: - Error Logging Helpers

extension LogService {

    /// Log an error with additional context
    /// - Parameters:
    ///   - error: The error to log
    ///   - context: Additional context about where/why the error occurred
    ///   - category: Log category
    func logError(_ error: Error, context: String, category: Category = .general) {
        let message = "\(context): \(error.localizedDescription)"
        self.error(message, category: category, error: error)
    }
}
