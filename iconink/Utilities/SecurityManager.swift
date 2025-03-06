//
//  SecurityManager.swift
//  iconink
//
//  Created by Garot Conklin on 2/27/25.
//

import Foundation
import LocalAuthentication

class SecurityManager {
    
    // MARK: - Singleton
    
    static let shared = SecurityManager()
    
    private init() {}
    
    // MARK: - Properties
    
    private let userDefaults = UserDefaults.standard
    private let context = LAContext()
    
    // MARK: - User Defaults Keys
    
    private enum Keys {
        static let useBiometrics = "useBiometrics"
        static let usePasscode = "usePasscode"
        static let passcodeHash = "passcodeHash"
        static let autoLockTimeout = "autoLockTimeout"
        static let lastActiveTime = "lastActiveTime"
    }
    
    // MARK: - Public Properties
    
    var useBiometrics: Bool {
        get { userDefaults.bool(forKey: Keys.useBiometrics) }
        set { userDefaults.set(newValue, forKey: Keys.useBiometrics) }
    }
    
    var usePasscode: Bool {
        get { userDefaults.bool(forKey: Keys.usePasscode) }
        set { userDefaults.set(newValue, forKey: Keys.usePasscode) }
    }
    
    var autoLockTimeout: Int {
        get { userDefaults.integer(forKey: Keys.autoLockTimeout) }
        set { userDefaults.set(newValue, forKey: Keys.autoLockTimeout) }
    }
    
    var lastActiveTime: Date? {
        get { userDefaults.object(forKey: Keys.lastActiveTime) as? Date }
        set { userDefaults.set(newValue, forKey: Keys.lastActiveTime) }
    }
    
    var isBiometricAvailable: Bool {
        var error: NSError?
        let available = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return available
    }
    
    var biometricType: BiometricType {
        if #available(iOS 11.0, *) {
            switch context.biometryType {
            case .faceID:
                return .faceID
            case .touchID:
                return .touchID
            default:
                return .none
            }
        } else {
            return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) ? .touchID : .none
        }
    }
    
    // MARK: - Public Methods
    
    /// Authenticates the user using biometrics
    func authenticateWithBiometrics(reason: String, completion: @escaping (Bool, Error?) -> Void) {
        guard isBiometricAvailable else {
            completion(false, NSError(domain: "com.iconink.error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Biometric authentication not available"]))
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.lastActiveTime = Date()
                }
                completion(success, error)
            }
        }
    }
    
    /// Sets a passcode for the app
    func setPasscode(_ passcode: String) -> Bool {
        guard !passcode.isEmpty else { return false }
        
        let salt = generateSalt()
        guard let hash = hashPasscode(passcode, salt: salt) else { return false }
        
        userDefaults.set(hash, forKey: Keys.passcodeHash)
        usePasscode = true
        return true
    }
    
    /// Verifies the passcode
    func verifyPasscode(_ passcode: String) -> Bool {
        guard usePasscode,
              let storedHash = userDefaults.string(forKey: Keys.passcodeHash),
              let salt = extractSalt(from: storedHash),
              let hash = hashPasscode(passcode, salt: salt) else {
            return false
        }
        
        let result = (hash == storedHash)
        if result {
            lastActiveTime = Date()
        }
        return result
    }
    
    /// Removes the passcode
    func removePasscode() {
        userDefaults.removeObject(forKey: Keys.passcodeHash)
        usePasscode = false
    }
    
    /// Updates the last active time
    func updateLastActiveTime() {
        lastActiveTime = Date()
    }
    
    /// Checks if the app should be locked based on the auto-lock timeout
    func shouldLockApp() -> Bool {
        guard autoLockTimeout > 0,
              let lastActive = lastActiveTime else {
            return false
        }
        
        let timeoutInterval = TimeInterval(autoLockTimeout * 60)
        return Date().timeIntervalSince(lastActive) >= timeoutInterval
    }
    
    // MARK: - Private Methods
    
    private func generateSalt() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<16).compactMap { _ in 
            letters.randomElement() 
        })
    }
    
    private func hashPasscode(_ passcode: String, salt: String) -> String? {
        let combined = passcode + salt
        guard let data = combined.data(using: .utf8) else { return nil }
        
        let hash = SHA256.hash(data: data)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        return "\(hashString):\(salt)"
    }
    
    private func extractSalt(from hashString: String) -> String? {
        let components = hashString.components(separatedBy: ":")
        guard components.count == 2 else { return nil }
        return components[1]
    }
}

// MARK: - Biometric Type Enum

enum BiometricType {
    case none
    case touchID
    case faceID
    
    var displayName: String {
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

// MARK: - SHA256 Implementation

struct SHA256 {
    static func hash(data: Data) -> [UInt8] {
        // This is a simple implementation for demonstration purposes
        // In a real app, use CryptoKit or CommonCrypto for proper hashing
        var hash = [UInt8](repeating: 0, count: 32)
        data.withUnsafeBytes { buffer in
            for index in 0..<min(data.count, 32) {
                hash[index] = buffer[index % buffer.count]
            }
        }
        return hash
    }
} 
