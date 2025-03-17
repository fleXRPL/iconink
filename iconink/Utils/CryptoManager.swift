import Foundation
import CryptoKit

class CryptoManager {
    enum CryptoError: Error {
        case keyDerivationFailed
        case encryptionFailed
        case decryptionFailed
        case invalidData
    }
    
    // PBKDF2 key derivation
    private static func deriveKey(from password: String, salt: Data) throws -> SymmetricKey {
        // Use PBKDF2 to derive a key from the password
        let passwordData = Data(password.utf8)
        
        // In a production app, you would use a higher iteration count (at least 10000)
        // and store the salt with the encrypted data
        let iterations = 10000
        let keyLength = 32 // 256 bits
        
        var derivedKeyData = Data(repeating: 0, count: keyLength)
        let result = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            salt.withUnsafeBytes { saltBytes in
                passwordData.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress, passwordBytes.count,
                        saltBytes.baseAddress, saltBytes.count,
                        CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedKeyBytes.baseAddress, derivedKeyBytes.count
                    )
                }
            }
        }
        
        guard result == kCCSuccess else {
            throw CryptoError.keyDerivationFailed
        }
        
        return SymmetricKey(data: derivedKeyData)
    }
    
    // Encrypt data with a password
    static func encrypt(data: Data, password: String) throws -> Data {
        // Generate a random salt
        let salt = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
        
        // Derive a key from the password and salt
        let key = try deriveKey(from: password, salt: salt)
        
        // Encrypt the data
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        // Combine salt, nonce, ciphertext, and tag into a single data object
        var encryptedData = Data()
        encryptedData.append(salt)
        encryptedData.append(sealedBox.nonce)
        encryptedData.append(sealedBox.ciphertext)
        encryptedData.append(sealedBox.tag)
        
        return encryptedData
    }
    
    // Decrypt data with a password
    static func decrypt(data: Data, password: String) throws -> Data {
        // Extract the components from the encrypted data
        guard data.count >= 16 + 12 + 16 else { // salt + nonce + minimum tag size
            throw CryptoError.invalidData
        }
        
        let salt = data.prefix(16)
        let nonce = data.subdata(in: 16..<(16 + 12))
        let ciphertextWithTag = data.suffix(from: 16 + 12)
        let ciphertext = ciphertextWithTag.prefix(ciphertextWithTag.count - 16)
        let tag = ciphertextWithTag.suffix(16)
        
        // Derive the key from the password and salt
        let key = try deriveKey(from: password, salt: salt)
        
        // Create a sealed box from the components
        let sealedBox = try AES.GCM.SealedBox(
            nonce: AES.GCM.Nonce(data: nonce),
            ciphertext: ciphertext,
            tag: tag
        )
        
        // Decrypt the data
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    // Encrypt a file with a password
    static func encryptFile(at sourceURL: URL, to destinationURL: URL, password: String) throws {
        // Read the source file
        let data = try Data(contentsOf: sourceURL)
        
        // Encrypt the data
        let encryptedData = try encrypt(data: data, password: password)
        
        // Write the encrypted data to the destination file
        try encryptedData.write(to: destinationURL)
    }
    
    // Decrypt a file with a password
    static func decryptFile(at sourceURL: URL, to destinationURL: URL, password: String) throws {
        // Read the encrypted file
        let encryptedData = try Data(contentsOf: sourceURL)
        
        // Decrypt the data
        let decryptedData = try decrypt(data: encryptedData, password: password)
        
        // Write the decrypted data to the destination file
        try decryptedData.write(to: destinationURL)
    }
} 
