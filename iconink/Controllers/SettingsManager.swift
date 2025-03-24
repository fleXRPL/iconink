import Foundation
import LocalAuthentication
import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

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

/// Manages app authentication and locking
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isLocked = false
    @Published var isAuthenticating = false
    
    private let securityManager = SecurityManager.shared
    private let settings = SettingsManager.shared
    
    private var lastActiveTimestamp = Date()
    private var lockTimer: Timer?
    
    private init() {
        // Initialize with locked state if app lock is enabled
        isLocked = settings.useAuthenticationLock
        
        // Start monitoring app state for auto-lock
        setupAppStateMonitoring()
    }
    
    /// Sets up app state monitoring for auto-lock functionality
    private func setupAppStateMonitoring() {
        #if canImport(UIKit)
        // Monitor app going to background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // Monitor app becoming active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        #else
        // Monitor app going to background on macOS
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
        
        // Monitor app becoming active on macOS
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        #endif
        
        // Start timer for checking inactivity
        startLockTimer()
    }
    
    /// Starts the lock timer based on settings
    private func startLockTimer() {
        stopLockTimer()
        
        // Only set timer if auto-lock is enabled with a non-zero timeout
        if settings.useAuthenticationLock && settings.autoLockTimeout > 0 {
            lockTimer = Timer.scheduledTimer(
                timeInterval: 60.0, // Check every minute
                target: self,
                selector: #selector(checkLockTimeout),
                userInfo: nil,
                repeats: true
            )
        }
    }
    
    /// Stops the lock timer
    private func stopLockTimer() {
        lockTimer?.invalidate()
        lockTimer = nil
    }
    
    /// Updates the last active timestamp
    func updateActivity() {
        lastActiveTimestamp = Date()
    }
    
    /// Authenticates the user using biometrics or device passcode
    func authenticateUser() {
        guard settings.useAuthenticationLock else {
            isLocked = false
            return
        }
        
        isAuthenticating = true
        
        securityManager.authenticateWithBiometrics(reason: "Unlock IconInk", fallbackTitle: nil) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthenticating = false
                
                if success {
                    self?.isLocked = false
                    self?.updateActivity()
                } else if let error = error {
                    print("Authentication failed: \(error.localizedDescription)")
                    // Keep app locked
                    self?.isLocked = true
                }
            }
        }
    }
    
    /// Locks the app manually
    func lockApp() {
        isLocked = true
    }
    
    // MARK: - Notification Handlers
    
    @objc private func appDidEnterBackground() {
        // Lock immediately if auto-lock timeout is set to 0
        if settings.useAuthenticationLock && settings.autoLockTimeout == 0 {
            isLocked = true
        }
    }
    
    @objc private func appDidBecomeActive() {
        // Check if we should be locked based on timeout
        checkLockTimeout()
        
        // Restart the timer
        startLockTimer()
    }
    
    @objc private func checkLockTimeout() {
        guard settings.useAuthenticationLock && !isLocked else { return }
        
        let timeout = settings.autoLockTimeout
        let timeoutInterval = TimeInterval(timeout * 60) // Convert to seconds
        
        // Check if we've exceeded the timeout
        if Date().timeIntervalSince(lastActiveTimestamp) >= timeoutInterval {
            isLocked = true
        }
    }
}

/// SwiftUI modifier to add authentication lock to a view
struct AuthenticationLockModifier: ViewModifier {
    @ObservedObject private var authManager = AuthenticationManager.shared
    
    public func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(authManager.isLocked)
                .onTapGesture {
                    AuthenticationManager.shared.updateActivity()
                }
            
            if authManager.isLocked {
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
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
                }
                .onTapGesture {
                    authManager.authenticateUser()
                }
            }
        }
        .onAppear {
            if authManager.isLocked {
                authManager.authenticateUser()
            }
        }
    }
}

extension View {
    func withAuthenticationLock() -> some View {
        modifier(AuthenticationLockModifier())
    }
} 
