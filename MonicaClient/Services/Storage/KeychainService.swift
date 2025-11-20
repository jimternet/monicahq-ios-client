import Foundation
import Security

/// Secure storage service for API credentials using iOS Keychain
class KeychainService {
    
    private let service = "com.monicahq.client"
    
    enum KeychainKey: String {
        case apiURL = "apiURL"
        case apiToken = "apiToken"
    }
    
    enum KeychainError: LocalizedError {
        case itemNotFound
        case duplicateItem
        case invalidData
        case unexpectedStatus(OSStatus)
        
        var errorDescription: String? {
            switch self {
            case .itemNotFound:
                return "Keychain item not found"
            case .duplicateItem:
                return "Keychain item already exists"
            case .invalidData:
                return "Invalid keychain data"
            case .unexpectedStatus(let status):
                return "Keychain error: \(status)"
            }
        }
    }
    
    /// Store a string value securely in the Keychain
    func store(_ value: String, for key: KeychainKey) throws {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data
        ]
        
        // Delete any existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// Retrieve a string value from the Keychain
    func retrieve(for key: KeychainKey) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let data = item as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return string
    }
    
    /// Delete a value from the Keychain
    func delete(for key: KeychainKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// Delete all stored credentials
    func deleteAllCredentials() {
        try? delete(for: .apiURL)
        try? delete(for: .apiToken)
    }
    
    /// Check if credentials exist
    func hasStoredCredentials() -> Bool {
        do {
            _ = try retrieve(for: .apiURL)
            _ = try retrieve(for: .apiToken)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Credentials structure
    struct Credentials {
        let apiURL: String
        let apiToken: String
    }
    
    /// Get stored credentials
    func getCredentials() -> Credentials? {
        do {
            let apiURL = try retrieve(for: .apiURL)
            let apiToken = try retrieve(for: .apiToken)
            return Credentials(apiURL: apiURL, apiToken: apiToken)
        } catch {
            return nil
        }
    }
    
    /// Save credentials
    func saveCredentials(apiURL: String, apiToken: String) {
        try? store(apiURL, for: .apiURL)
        try? store(apiToken, for: .apiToken)
    }
    
    /// Delete all credentials (alias for deleteAllCredentials)
    func deleteCredentials() {
        deleteAllCredentials()
    }
}