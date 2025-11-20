import Foundation
import SwiftUI
import CoreData

/// View model for managing settings and app configuration
@MainActor
class SettingsViewModel: ObservableObject {
    @Published var instanceURL: String?
    @Published var maskedToken: String = "••••••••••••••"
    @Published var cacheSize: String = "Calculating..."
    @Published var isCalculatingCache = false
    @Published var appVersion: String = ""
    @Published var buildNumber: String = ""
    @Published var debugMode: Bool = false
    @Published var instanceType: AuthCredentials.InstanceType?
    
    private let keychainService = KeychainService()
    private let userDefaultsService = UserDefaultsService()
    private let cacheService = CacheService()
    
    init() {
        loadAppInfo()
        loadDebugMode()
    }
    
    func loadSettings() async {
        if let credentials = keychainService.getCredentials() {
            instanceURL = credentials.apiURL
            
            // Mask the token, showing only first and last 4 characters
            if credentials.apiToken.count > 8 {
                let prefix = String(credentials.apiToken.prefix(4))
                let suffix = String(credentials.apiToken.suffix(4))
                maskedToken = "\(prefix)••••••••\(suffix)"
            } else {
                maskedToken = "••••••••••••••"
            }
            
            // Determine instance type
            if credentials.apiURL.contains("monicahq.com") {
                instanceType = .cloud
            } else {
                instanceType = .selfHosted
            }
        }
    }
    
    func calculateCacheSize() async {
        isCalculatingCache = true
        
        // Simulate cache calculation
        // In a real app, you'd calculate actual Core Data store size
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            let resourceKeys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .isDirectoryKey]
            let enumerator = fileManager.enumerator(
                at: documentsURL,
                includingPropertiesForKeys: resourceKeys,
                options: [.skipsHiddenFiles],
                errorHandler: nil
            )!
            
            var totalSize: Int64 = 0
            
            for case let fileURL as URL in enumerator {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                if let isDirectory = resourceValues.isDirectory, !isDirectory,
                   let fileSize = resourceValues.totalFileAllocatedSize {
                    totalSize += Int64(fileSize)
                }
            }
            
            cacheSize = formatBytes(totalSize)
        } catch {
            cacheSize = "Unknown"
        }
        
        isCalculatingCache = false
    }
    
    func clearCache() async {
        isCalculatingCache = true
        
        // Clear in-memory cache
        cacheService.clearCache()
        
        // Clear Core Data cache
        // This would be implemented through DataController
        NotificationCenter.default.post(name: Notification.Name("ClearCoreDataCache"), object: nil)
        
        // Recalculate size
        await calculateCacheSize()
    }
    
    func logout() {
        // Clear credentials
        keychainService.deleteCredentials()
        
        // Clear cache
        cacheService.clearCache()
        
        // Clear user defaults
        userDefaultsService.clearAll()
        
        // Post logout notification
        NotificationCenter.default.post(name: Notification.Name("UserDidLogout"), object: nil)
    }
    
    func switchInstance() {
        logout()
        // The app will automatically show onboarding when credentials are cleared
    }
    
    func updateAPIToken(_ newToken: String) async throws {
        guard let credentials = keychainService.getCredentials() else {
            throw MonicaAPIError.invalidCredentials
        }
        
        // Test the new token
        let testClient = MonicaAPIClient(
            baseURL: credentials.apiURL,
            apiToken: newToken,
            cacheService: cacheService
        )
        
        try await testClient.testConnection()
        
        // If successful, save the new token
        keychainService.saveCredentials(
            apiURL: credentials.apiURL,
            apiToken: newToken
        )
        
        // Reload settings
        await loadSettings()
        
        // Notify that credentials have been updated
        NotificationCenter.default.post(name: Notification.Name("CredentialsUpdated"), object: nil)
    }
    
    private func loadAppInfo() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            appVersion = version
        } else {
            appVersion = "1.0.0"
        }
        
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            buildNumber = build
        } else {
            buildNumber = "1"
        }
    }
    
    private func loadDebugMode() {
        debugMode = userDefaultsService.getDebugMode()
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: bytes)
    }
}

