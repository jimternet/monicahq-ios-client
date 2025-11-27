import Foundation

/// User preferences and app settings storage using UserDefaults
class UserDefaultsService {
    
    private let userDefaults = UserDefaults.standard
    
    enum SettingsKey: String {
        case lastSyncDate = "lastSyncDate"
        case contactsPerPage = "contactsPerPage"
        case enablePushNotifications = "enablePushNotifications"
        case preferredDateFormat = "preferredDateFormat"
        case cacheSize = "cacheSize"
        case appVersion = "appVersion"
        case onboardingCompleted = "onboardingCompleted"
        case darkModePreference = "darkModePreference"
        case searchDebounceTime = "searchDebounceTime"
        case debugMode = "debugMode"
        case defaultConversationType = "defaultConversationType"
    }
    
    // MARK: - Generic Storage Methods
    
    func set<T>(_ value: T, for key: SettingsKey) {
        userDefaults.set(value, forKey: key.rawValue)
    }
    
    func get<T>(_ type: T.Type, for key: SettingsKey) -> T? {
        return userDefaults.object(forKey: key.rawValue) as? T
    }
    
    func remove(for key: SettingsKey) {
        userDefaults.removeObject(forKey: key.rawValue)
    }
    
    // MARK: - Specific Settings
    
    var lastSyncDate: Date? {
        get { get(Date.self, for: .lastSyncDate) }
        set { set(newValue as Any, for: .lastSyncDate) }
    }
    
    var contactsPerPage: Int {
        get { get(Int.self, for: .contactsPerPage) ?? 50 }
        set { set(newValue, for: .contactsPerPage) }
    }
    
    var enablePushNotifications: Bool {
        get { get(Bool.self, for: .enablePushNotifications) ?? true }
        set { set(newValue, for: .enablePushNotifications) }
    }
    
    var preferredDateFormat: String {
        get { get(String.self, for: .preferredDateFormat) ?? "relative" }
        set { set(newValue, for: .preferredDateFormat) }
    }
    
    var cacheSize: Int {
        get { get(Int.self, for: .cacheSize) ?? 0 }
        set { set(newValue, for: .cacheSize) }
    }
    
    var appVersion: String? {
        get { get(String.self, for: .appVersion) }
        set { set(newValue as Any, for: .appVersion) }
    }
    
    var onboardingCompleted: Bool {
        get { get(Bool.self, for: .onboardingCompleted) ?? false }
        set { set(newValue, for: .onboardingCompleted) }
    }
    
    var darkModePreference: String {
        get { get(String.self, for: .darkModePreference) ?? "system" }
        set { set(newValue, for: .darkModePreference) }
    }
    
    var searchDebounceTime: Double {
        get { get(Double.self, for: .searchDebounceTime) ?? 0.3 }
        set { set(newValue, for: .searchDebounceTime) }
    }
    
    var debugMode: Bool {
        get { get(Bool.self, for: .debugMode) ?? false }
        set { set(newValue, for: .debugMode) }
    }

    /// Default conversation type ID for quick logging
    /// nil means use the first available type from the API
    var defaultConversationType: Int? {
        get { get(Int.self, for: .defaultConversationType) }
        set {
            if let value = newValue {
                set(value, for: .defaultConversationType)
            } else {
                remove(for: .defaultConversationType)
            }
        }
    }

    // MARK: - Utility Methods
    
    func resetToDefaults() {
        SettingsKey.allCases.forEach { key in
            remove(for: key)
        }
    }
    
    func exportSettings() -> [String: Any] {
        var settings: [String: Any] = [:]
        SettingsKey.allCases.forEach { key in
            if let value = userDefaults.object(forKey: key.rawValue) {
                settings[key.rawValue] = value
            }
        }
        return settings
    }
    
    // MARK: - Additional Methods
    
    func getDebugMode() -> Bool {
        return debugMode
    }
    
    func clearAll() {
        resetToDefaults()
    }
}

// MARK: - SettingsKey CaseIterable
extension UserDefaultsService.SettingsKey: CaseIterable {}