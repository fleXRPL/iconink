import Foundation
import LocalAuthentication
import CryptoKit

/// SecurityManager handles all security-related functionality for the app
/// including biometric authentication and data encryption/decryption
class SecurityManager {
    static let shared = SecurityManager()
    
    private init() {}
    
    // MARK: - Biometric Authentication
    
    /// Authenticates the user using biometric authentication (Face ID or Touch ID)
    /// - Parameters:
    ///   - reason: The reason for authentication to display to the user
    ///   - completion: Callback with authentication result and optional error
    func authenticateWithBiometrics(reason: String, completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // Use biometric authentication
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    completion(success, authenticationError)
                }
            }
        } else {
            // Biometric authentication not available
            completion(false, error)
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
    
    // MARK: - Data Encryption
    
    /// Encrypts data using AES-GCM encryption
    /// - Parameter data: The data to encrypt
    /// - Returns: Encrypted data or nil if encryption failed
    func encryptData(_ data: Data) -> Data? {
        do {
            // Generate a random symmetric key
            let key = SymmetricKey(size: .bits256)
            
            // Store the key securely in the keychain
            // In a real app, you would store this key securely and retrieve it when needed
            
            // Generate a random nonce
            let nonce = try AES.GCM.Nonce()
            
            // Encrypt the data
            let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
            
            // Return the combined nonce and ciphertext
            return sealedBox.combined
        } catch {
            print("Encryption error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Decrypts data that was encrypted using AES-GCM encryption
    /// - Parameters:
    ///   - encryptedData: The data to decrypt
    ///   - key: The symmetric key used for encryption
    /// - Returns: Decrypted data or nil if decryption failed
    func decryptData(_ encryptedData: Data, using key: SymmetricKey) -> Data? {
        do {
            // Create a sealed box from the combined data
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            
            // Decrypt the data
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            print("Decryption error: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Secure Storage
    
    /// Saves data securely to the keychain
    /// - Parameters:
    ///   - data: The data to save
    ///   - key: The key to use for retrieving the data
    /// - Returns: Whether the operation was successful
    func saveToKeychain(data: Data, forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Retrieves data from the keychain
    /// - Parameter key: The key used to save the data
    /// - Returns: The retrieved data or nil if not found
    func retrieveFromKeychain(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        } else {
            return nil
        }
    }
}

/// Enum representing the type of biometric authentication available
enum BiometricType {
    case none
    case touchID
    case faceID
    
    var description: String {
        switch self {
        case .none:
            return "None"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        }
    }
}