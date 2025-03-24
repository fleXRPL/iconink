import Foundation
import SwiftUI

/// SettingsManager handles all app settings and preferences
class SettingsManager {
    static let shared = SettingsManager()
    
    // MARK: - Security Settings
    
    /// Key for storing the authentication lock preference
    private let authLockKey = "useAuthenticationLock"
    
    /// Key for storing the data encryption preference
    private let encryptDataKey = "encryptData"
    
    /// Key for storing the default consent form template
    private let defaultConsentKey = "defaultConsent"
    
    /// Key for storing the auto-lock timeout
    private let autoLockTimeoutKey = "autoLockTimeout"
    
    private init() {}
    
    // MARK: - Authentication Settings
    
    /// Gets or sets whether authentication lock is enabled
    var useAuthenticationLock: Bool {
        get {
            return UserDefaults.standard.bool(forKey: authLockKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: authLockKey)
        }
    }
    
    /// Gets or sets whether data encryption is enabled
    var encryptData: Bool {
        get {
            return UserDefaults.standard.bool(forKey: encryptDataKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: encryptDataKey)
        }
    }
    
    /// Gets or sets the auto-lock timeout in minutes (0 = never)
    var autoLockTimeout: Int {
        get {
            return UserDefaults.standard.integer(forKey: autoLockTimeoutKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: autoLockTimeoutKey)
        }
    }
    
    // MARK: - Consent Form Settings
    
    /// Gets or sets the default consent form template
    var defaultConsentTemplate: String {
        get {
            return UserDefaults.standard.string(forKey: defaultConsentKey) ?? "Standard"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: defaultConsentKey)
        }
    }
    
    /// Available consent form templates
    let availableTemplates = ["Standard", "Tattoo", "Piercing", "Microblading"]
    
    // MARK: - App Settings
    
    /// Resets all settings to default values
    func resetToDefaults() {
        useAuthenticationLock = false
        encryptData = false
        defaultConsentTemplate = "Standard"
        autoLockTimeout = 5 // 5 minutes default
    }
    
    /// Checks if biometric authentication is available and returns the type
    func checkBiometricAvailability() -> (available: Bool, type: BiometricType) {
        return SecurityManager.shared.biometricAuthenticationAvailability()
    }
}
