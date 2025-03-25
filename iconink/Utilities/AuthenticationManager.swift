import Foundation
import LocalAuthentication
import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

// Import needed managers

/// Manages application settings and preferences
class SettingsManager {
    static let shared = SettingsManager()
    
    // Keys for UserDefaults
    private let useAuthenticationLockKey = "useAuthenticationLock"
    private let encryptDataKey = "encryptData"
    private let defaultConsentTemplateKey = "defaultConsent"
    private let autoLockTimeoutKey = "autoLockTimeout"
    private let darkModeKey = "darkMode"
    
    // Default values
    private let defaultAutoLockTimeout = 5 // minutes
    
    // Available consent form templates
    let availableTemplates = ["Standard", "Custom", "Detailed", "Minor"]
    
    private init() {
        // Set initial defaults if not already set
        if !UserDefaults.standard.bool(forKey: "initialDefaultsSet") {
            resetToDefaults()
            UserDefaults.standard.set(true, forKey: "initialDefaultsSet")
        }
    }
    
    // MARK: - Access Properties
    
    /// Whether to use authentication lock (Face ID, Touch ID)
    var useAuthenticationLock: Bool {
        get { UserDefaults.standard.bool(forKey: useAuthenticationLockKey) }
        set { UserDefaults.standard.set(newValue, forKey: useAuthenticationLockKey) }
    }
    
    /// Whether to encrypt sensitive data
    var encryptData: Bool {
        get { UserDefaults.standard.bool(forKey: encryptDataKey) }
        set { UserDefaults.standard.set(newValue, forKey: encryptDataKey) }
    }
    
    /// Default consent form template
    var defaultConsentTemplate: String {
        get { UserDefaults.standard.string(forKey: defaultConsentTemplateKey) ?? "Standard" }
        set { UserDefaults.standard.set(newValue, forKey: defaultConsentTemplateKey) }
    }
    
    /// Auto-lock timeout in minutes
    var autoLockTimeout: Int {
        get { UserDefaults.standard.integer(forKey: autoLockTimeoutKey) }
        set { UserDefaults.standard.set(newValue, forKey: autoLockTimeoutKey) }
    }
    
    /// Dark mode setting
    var darkMode: Bool {
        get { UserDefaults.standard.bool(forKey: darkModeKey) }
        set { UserDefaults.standard.set(newValue, forKey: darkModeKey) }
    }
    
    // MARK: - Methods
    
    /// Resets all settings to default values
    func resetToDefaults() {
        UserDefaults.standard.set(false, forKey: useAuthenticationLockKey)
        UserDefaults.standard.set(false, forKey: encryptDataKey)
        UserDefaults.standard.set("Standard", forKey: defaultConsentTemplateKey)
        UserDefaults.standard.set(defaultAutoLockTimeout, forKey: autoLockTimeoutKey)
        UserDefaults.standard.set(false, forKey: darkModeKey)
    }
    
    /// Checks if biometric authentication is available
    /// - Returns: A tuple with availability status and authentication type
    func checkBiometricAvailability() -> (available: Bool, type: BiometricType) {
        let context = LAContext()
        var error: NSError?
        
        let available = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        var biometricType: BiometricType = .none
        if available {
            if #available(iOS 11.0, macOS 10.13.2, *) {
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
}

/// SecurityManager class placeholder
class SecurityManager {
    static let shared = SecurityManager()
    
    func authenticateWithBiometrics(reason: String, fallbackTitle: String?, completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                completion(success, error)
            }
        } else {
            completion(false, error)
        }
    }
}

/// AuthenticationManager handles app authentication and locking functionality
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var isLocked = false
    @Published var isAuthenticating = false
    
    private var lockTimer: Timer?
    private var lastActiveTime = Date()
    
    private let securityManager = SecurityManager.shared
    private let settings = SettingsManager.shared
    
    private init() {
        // Check if authentication is required
        if SettingsManager.shared.useAuthenticationLock {
            isLocked = true
            isAuthenticated = false
        } else {
            isLocked = false
            isAuthenticated = true
        }
        
        // Setup app lifecycle observers
        setupNotifications()
    }
    
    // MARK: - Authentication Methods
    
    /// Authenticates the user using biometric authentication
    /// - Parameter completion: Callback with authentication result
    func authenticateUser(completion: ((Bool) -> Void)? = nil) {
        // Skip authentication if not required
        if !SettingsManager.shared.useAuthenticationLock {
            isAuthenticated = true
            isLocked = false
            completion?(true)
            return
        }
        
        // Set authenticating state
        isAuthenticating = true
        
        // Use biometric authentication
        SecurityManager.shared.authenticateWithBiometrics(reason: "Unlock IconInk") { success, error in
            DispatchQueue.main.async {
                self.isAuthenticating = false
                
                if success {
                    self.isAuthenticated = true
                    self.isLocked = false
                    self.resetLockTimer()
                } else {
                    self.isAuthenticated = false
                    self.isLocked = true
                    
                    if let error = error {
                        print("Authentication error: \(error.localizedDescription)")
                    }
                }
                
                completion?(success)
            }
        }
    }
    
    /// Locks the app, requiring authentication to unlock
    func lockApp() {
        isLocked = true
        isAuthenticated = false
        invalidateLockTimer()
    }
    
    // MARK: - Auto-Lock Timer
    
    /// Resets the auto-lock timer
    func resetLockTimer() {
        // Update last active time
        lastActiveTime = Date()
        
        // Cancel existing timer
        invalidateLockTimer()
        
        // Get timeout from settings
        let timeout = SettingsManager.shared.autoLockTimeout
        
        // Skip if timeout is 0 (never lock)
        if timeout == 0 || !SettingsManager.shared.useAuthenticationLock {
            return
        }
        
        // Create new timer
        lockTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Check if app should be locked
            let timeElapsed = Date().timeIntervalSince(self.lastActiveTime) / 60
            if timeElapsed >= Double(timeout) {
                DispatchQueue.main.async {
                    self.lockApp()
                }
            }
        }
    }
    
    /// Invalidates the auto-lock timer
    private func invalidateLockTimer() {
        lockTimer?.invalidate()
        lockTimer = nil
    }
    
    // MARK: - App Lifecycle
    
    /// Sets up notification observers for app lifecycle events
    private func setupNotifications() {
        // App will enter background
        NotificationCenter.default.addObserver(
            self, 
            selector: #selector(appWillResignActive), 
            name: UIApplication.willResignActiveNotification, 
            object: nil
        )
        
        // App will enter foreground
        NotificationCenter.default.addObserver(
            self, 
            selector: #selector(appWillEnterForeground), 
            name: UIApplication.willEnterForegroundNotification, 
            object: nil
        )
    }
    
    /// Called when app enters background
    @objc private func appWillResignActive() {
        // Lock immediately if set to 0
        if SettingsManager.shared.autoLockTimeout == 0 && SettingsManager.shared.useAuthenticationLock {
            lockApp()
        }
    }
    
    /// Called when app enters foreground
    @objc private func appWillEnterForeground() {
        // Check if authentication is required
        if isLocked {
            authenticateUser()
        } else {
            resetLockTimer()
        }
    }
}

/// View modifier to apply authentication lock to a view
struct AuthenticationLockModifier: ViewModifier {
    @ObservedObject private var authManager = AuthenticationManager.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(authManager.isLocked)
                .blur(radius: authManager.isLocked ? 10 : 0)
            
            if authManager.isLocked {
                VStack(spacing: 20) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("IconInk is Locked")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    Text("Tap to unlock")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    if authManager.isAuthenticating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.top)
                    }
                    
                    Button("Unlock") {
                        authManager.authenticateUser()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.top)
                }
                .padding()
                .background(Color.systemBackground)
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding(30)
                .transition(.opacity)
            }
        }
        .onAppear {
            // Reset timer when view appears
            if !authManager.isLocked {
                authManager.resetLockTimer()
            }
        }
    }
}

extension View {
    /// Applies authentication lock to a view
    func withAuthenticationLock() -> some View {
        modifier(AuthenticationLockModifier())
    }
}

// Helper extension for Color
extension Color {
    static let systemBackground = Color(UIColor.systemBackground)
}
