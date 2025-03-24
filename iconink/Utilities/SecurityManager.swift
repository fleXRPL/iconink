import Foundation
import LocalAuthentication
import CryptoKit
import CoreData

/// SecurityManager handles all security-related functionality for the app
/// including biometric authentication and data encryption/decryption
class SecurityManager {
    static let shared = SecurityManager()
    
    // Keychain service and key identifiers
    private let serviceIdentifier = "com.iconink.secureStorage"
    private let encryptionKeyIdentifier = "com.iconink.encryptionKey"
    
    // Key for storing authentication preference
    private let biometricAuthEnabledKey = "biometricAuthEnabled"
    private let appLockEnabledKey = "appLockEnabled"
    
    // Error logger
    private let securityLogger = SecurityLogger()
    
    private init() {
        // Generate encryption key if it doesn't exist
        ensureEncryptionKeyExists()
    }
    
    // MARK: - Biometric Authentication
    
    /// Authenticates the user using biometric authentication (Face ID or Touch ID)
    /// - Parameters:
    ///   - reason: The reason for authentication to display to the user
    ///   - fallbackTitle: Optional title for the fallback button
    ///   - completion: Callback with authentication result and optional error
    func authenticateWithBiometrics(reason: String, fallbackTitle: String? = nil, completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        // Configure fallback title if provided
        if let fallbackTitle = fallbackTitle {
            context.localizedFallbackTitle = fallbackTitle
        }
        
        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // Use biometric authentication
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if !success {
                        self.securityLogger.logAuthenticationFailure(error: authenticationError)
                    }
                    completion(success, authenticationError)
                }
            }
        } else {
            // Try device passcode as fallback
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if !success {
                        self.securityLogger.logAuthenticationFailure(error: authenticationError)
                    }
                    completion(success, authenticationError)
                }
            }
        }
    }
    
    /// Checks if biometric authentication is available on the device
    /// - Returns: A tuple containing availability status and authentication type
    func biometricAuthenticationAvailability() -> (available: Bool, type: BiometricType) {
        let context = LAContext()
        var error: NSError?
        
        let available = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        var biometricType: BiometricType = .none
        if available {
            if #available(iOS 11.0, *) {
                switch context.biometryType {
                case .faceID:
                    biometricType = .faceID
                case .touchID:
                    biometricType = .touchID
                default:
                    biometricType = .none
                }
            } else {
                biometricType = .touchID
            }
        }
        
        return (available, biometricType)
    }
    
    /// Gets user-friendly description of authentication error
    /// - Parameter error: The authentication error
    /// - Returns: User-friendly error message
    func authenticationErrorDescription(_ error: Error?) -> String {
        guard let error = error as? LAError else {
            return "Authentication failed"
        }
        
        switch error.code {
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .userCancel:
            return "Authentication was canceled by the user."
        case .userFallback:
            return "Authentication fallback was selected."
        case .biometryNotAvailable:
            return "Biometric authentication is not available on this device."
        case .biometryNotEnrolled:
            return "Biometric authentication is not set up on this device."
        case .biometryLockout:
            return "Biometric authentication is locked out due to too many failed attempts."
        default:
            return "Authentication failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Security Settings
    
    /// Sets whether biometric authentication is enabled
    /// - Parameter enabled: Whether to enable biometric authentication
    func setBiometricAuthEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: biometricAuthEnabledKey)
    }
    
    /// Checks if biometric authentication is enabled
    /// - Returns: Whether biometric authentication is enabled
    func isBiometricAuthEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: biometricAuthEnabledKey)
    }
    
    /// Sets whether app lock is enabled
    /// - Parameter enabled: Whether to enable app lock
    func setAppLockEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: appLockEnabledKey)
    }
    
    /// Checks if app lock is enabled
    /// - Returns: Whether app lock is enabled
    func isAppLockEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: appLockEnabledKey)
    }
    
    // MARK: - Data Encryption
    
    /// Ensures that an encryption key exists in the keychain
    private func ensureEncryptionKeyExists() {
        // Check if we already have a key
        if retrieveEncryptionKey() == nil {
            // Generate a new key and store it
            let newKey = SymmetricKey(size: .bits256)
            let keyData = newKey.withUnsafeBytes { Data($0) }
            
            _ = saveToKeychain(data: keyData, forKey: encryptionKeyIdentifier, withService: serviceIdentifier)
        }
    }
    
    /// Retrieves the app's encryption key from the keychain
    /// - Returns: The encryption key or nil if not found
    private func retrieveEncryptionKey() -> SymmetricKey? {
        guard let keyData = retrieveFromKeychain(forKey: encryptionKeyIdentifier, withService: serviceIdentifier) else {
            return nil
        }
        
        return SymmetricKey(data: keyData)
    }
    
    /// Encrypts data using AES-GCM encryption
    /// - Parameter data: The data to encrypt
    /// - Returns: Encrypted data and nonce, or nil if encryption failed
    func encryptData(_ data: Data) -> Data? {
        guard let key = retrieveEncryptionKey() else {
            securityLogger.logError(message: "Failed to retrieve encryption key")
            return nil
        }
        
        do {
            // Generate a random nonce
            let nonce = try AES.GCM.Nonce()
            
            // Encrypt the data
            let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
            
            // Return the combined nonce and ciphertext
            return sealedBox.combined
        } catch {
            securityLogger.logError(message: "Encryption error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Encrypts a string using AES-GCM encryption
    /// - Parameter string: The string to encrypt
    /// - Returns: Base64-encoded encrypted string, or nil if encryption failed
    func encryptString(_ string: String) -> String? {
        guard let data = string.data(using: .utf8) else {
            return nil
        }
        
        guard let encryptedData = encryptData(data) else {
            return nil
        }
        
        return encryptedData.base64EncodedString()
    }
    
    /// Decrypts data that was encrypted using AES-GCM encryption
    /// - Parameter encryptedData: The data to decrypt
    /// - Returns: Decrypted data or nil if decryption failed
    func decryptData(_ encryptedData: Data) -> Data? {
        guard let key = retrieveEncryptionKey() else {
            securityLogger.logError(message: "Failed to retrieve encryption key")
            return nil
        }
        
        do {
            // Create a sealed box from the combined data
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            
            // Decrypt the data
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            securityLogger.logError(message: "Decryption error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Decrypts a base64-encoded encrypted string
    /// - Parameter base64String: The base64-encoded encrypted string
    /// - Returns: Decrypted string, or nil if decryption failed
    func decryptString(_ base64String: String) -> String? {
        guard let data = Data(base64Encoded: base64String) else {
            return nil
        }
        
        guard let decryptedData = decryptData(data) else {
            return nil
        }
        
        return String(data: decryptedData, encoding: .utf8)
    }
    
    // MARK: - Secure Data Handling
    
    /// Securely stores sensitive client data
    /// - Parameter client: The client whose data needs to be secured
    /// - Returns: Whether the operation was successful
    func secureClientData(_ client: NSManagedObject) -> Bool {
        // Encrypt sensitive fields
        if let idNumber = client.value(forKey: "idNumber") as? String, !idNumber.isEmpty {
            client.setValue(encryptString(idNumber), forKey: "idNumber")
        }
        
        // Add other sensitive fields as needed
        return true
    }
    
    /// Retrieves and decrypts sensitive client data
    /// - Parameter client: The client whose data needs to be decrypted
    /// - Returns: Whether the operation was successful
    func retrieveSecureClientData(_ client: NSManagedObject) -> Bool {
        // Decrypt sensitive fields
        if let encryptedIdNumber = client.value(forKey: "idNumber") as? String {
            client.setValue(decryptString(encryptedIdNumber), forKey: "idNumber")
        }
        
        // Add other sensitive fields as needed
        return true
    }
    
    // MARK: - Secure Storage
    
    /// Saves data securely to the keychain
    /// - Parameters:
    ///   - data: The data to save
    ///   - key: The key to use for retrieving the data
    ///   - service: The service identifier
    /// - Returns: Whether the operation was successful
    func saveToKeychain(data: Data, forKey key: String, withService service: String? = nil) -> Bool {
        let service = service ?? serviceIdentifier
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        let success = status == errSecSuccess
        
        if !success {
            securityLogger.logKeychainError(status: status, operation: "save", key: key)
        }
        
        return success
    }
    
    /// Retrieves data from the keychain
    /// - Parameters:
    ///   - key: The key used to save the data
    ///   - service: The service identifier
    /// - Returns: The retrieved data or nil if not found
    func retrieveFromKeychain(forKey key: String, withService service: String? = nil) -> Data? {
        let service = service ?? serviceIdentifier
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        } else if status != errSecItemNotFound {
            securityLogger.logKeychainError(status: status, operation: "retrieve", key: key)
        }
        
        return nil
    }
    
    /// Deletes an item from the keychain
    /// - Parameters:
    ///   - key: The key of the item to delete
    ///   - service: The service identifier
    /// - Returns: Whether the operation was successful
    func deleteFromKeychain(forKey key: String, withService service: String? = nil) -> Bool {
        let service = service ?? serviceIdentifier
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        let success = status == errSecSuccess || status == errSecItemNotFound
        
        if !success {
            securityLogger.logKeychainError(status: status, operation: "delete", key: key)
        }
        
        return success
    }
    
    /// Clears all app-related items from the keychain
    func clearAllKeychainItems() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            securityLogger.logKeychainError(status: status, operation: "clear all", key: "all")
        }
    }
}

/// Helper class for logging security-related events
private class SecurityLogger {
    private let logIdentifier = "SecurityManager"
    
    func logError(message: String) {
        NSLog("\(logIdentifier): \(message)")
    }
    
    func logAuthenticationFailure(error: Error?) {
        if let error = error {
            NSLog("\(logIdentifier): Authentication failed - \(error.localizedDescription)")
        } else {
            NSLog("\(logIdentifier): Authentication failed - No error provided")
        }
    }
    
    func logKeychainError(status: OSStatus, operation: String, key: String) {
        let message: String
        
        switch status {
        case errSecDuplicateItem:
            message = "Item already exists"
        case errSecItemNotFound:
            message = "Item not found"
        case errSecAuthFailed:
            message = "Authentication failed"
        case errSecDecode:
            message = "Decode failed"
        case errSecNotAvailable, errSecBadReq:
            message = "Service not available"
        default:
            message = "Unknown error (\(status))"
        }
        NSLog("\(logIdentifier): Keychain \(operation) failed for key '\(key)' - \(message)")
    }
}
