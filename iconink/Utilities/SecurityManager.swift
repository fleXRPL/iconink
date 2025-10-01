import Foundation
import LocalAuthentication
import CryptoKit

/// Manages security operations including biometric authentication and data encryption
class SecurityManager {
    static let shared = SecurityManager()
    
    private init() {}
    
    /// Authenticates user using biometrics or device passcode
    /// - Parameters:
    ///   - reason: The reason for authentication
    ///   - fallbackTitle: Optional fallback title for passcode entry
    ///   - completion: Completion handler with success status and error
    func authenticateWithBiometrics(reason: String, fallbackTitle: String?, completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    completion(success, error)
                }
            }
        } else {
            // Fallback to device passcode
            let fallbackReason = fallbackTitle ?? "Enter your passcode to continue"
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: fallbackReason) { success, error in
                DispatchQueue.main.async {
                    completion(success, error)
                }
            }
        }
    }
    
    /// Encrypts data using AES encryption
    /// - Parameter data: The data to encrypt
    /// - Returns: Encrypted data or nil if encryption fails
    func encryptData(_ data: Data) -> Data? {
        do {
            let key = SymmetricKey(size: .bits256)
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            print("Encryption failed: \(error)")
            return nil
        }
    }
    
    /// Decrypts data using AES decryption
    /// - Parameter encryptedData: The encrypted data
    /// - Returns: Decrypted data or nil if decryption fails
    func decryptData(_ encryptedData: Data) -> Data? {
        do {
            let key = SymmetricKey(size: .bits256)
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            print("Decryption failed: \(error)")
            return nil
        }
    }
    
    /// Generates a secure random key
    /// - Returns: A secure random key
    func generateSecureKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
}