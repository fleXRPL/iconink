import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @AppStorage("useAuthenticationLock") private var useAuthenticationLock = false
    @AppStorage("encryptData") private var encryptData = false
    @AppStorage("defaultConsent") private var defaultConsent = "Standard"
    @AppStorage("autoLockTimeout") private var autoLockTimeout = 5
    @AppStorage("darkMode") private var darkMode = false
    
    @State private var biometricType: BiometricType = .none
    @State private var isBiometricAvailable = false
    @State private var showingResetAlert = false
    
    private let timeoutOptions = [0, 1, 5, 15, 30, 60]
    private let settingsManager = SettingsManager.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Security")) {
                    Toggle("App Authentication Lock", isOn: $useAuthenticationLock)
                        .onChange(of: useAuthenticationLock) { newValue in
                            if newValue {
                                // Check if biometric auth is available
                                let (available, type) = settingsManager.checkBiometricAvailability()
                                isBiometricAvailable = available
                                biometricType = type
                                
                                if !available {
                                    // Reset if not available
                                    useAuthenticationLock = false
                                }
                            }
                        }
                    
                    if useAuthenticationLock {
                        Picker("Auto-Lock Timeout", selection: $autoLockTimeout) {
                            Text("Immediately").tag(0)
                            Text("After 1 minute").tag(1)
                            Text("After 5 minutes").tag(5)
                            Text("After 15 minutes").tag(15)
                            Text("After 30 minutes").tag(30)
                            Text("After 1 hour").tag(60)
                        }
                        
                        Text("The app will require \(biometricType.description) authentication to unlock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle("Encrypt Data", isOn: $encryptData)
                        .disabled(!useAuthenticationLock)
                    
                    if encryptData {
                        Text("PDF exports and sensitive data will be encrypted")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Consent Forms")) {
                    Picker("Default Template", selection: $defaultConsent) {
                        ForEach(settingsManager.availableTemplates, id: \.self) { template in
                            Text(template).tag(template)
                        }
                    }
                }
                
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $darkMode)
                }
                
                Section {
                    Button("Reset All Settings") {
                        showingResetAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                Section(header: Text("About")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("IconInk")
                            .font(.headline)
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer().frame(height: 10)
                        
                        Text("© 2025 IconInk")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                // Check biometric availability on appear
                let (available, type) = settingsManager.checkBiometricAvailability()
                isBiometricAvailable = available
                biometricType = type
                
                if useAuthenticationLock && !available {
                    useAuthenticationLock = false
                }
            }
            .alert("Reset Settings", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    settingsManager.resetToDefaults()
                    // Update local state to match defaults
                    useAuthenticationLock = settingsManager.useAuthenticationLock
                    encryptData = settingsManager.encryptData
                    defaultConsent = settingsManager.defaultConsentTemplate
                    autoLockTimeout = settingsManager.autoLockTimeout
                }
            } message: {
                Text("This will reset all settings to their default values. This action cannot be undone.")
            }
        }
    }
}

#Preview {
    SettingsView()
}
