import SwiftUI

struct SettingsView: View {
    @AppStorage("useAuthenticationLock") private var useAuthenticationLock = false
    @AppStorage("defaultConsent") private var defaultConsent = "Standard"
    @AppStorage("darkMode") private var darkMode = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Security")) {
                    Toggle("App Authentication Lock", isOn: $useAuthenticationLock)
                    
                    if useAuthenticationLock {
                        Text("The app will require Face ID or Touch ID authentication to unlock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Defaults")) {
                    Picker("Default Consent Form", selection: $defaultConsent) {
                        Text("Standard").tag("Standard")
                        Text("Tattoo").tag("Tattoo")
                        Text("Piercing").tag("Piercing")
                        Text("Microblading").tag("Microblading")
                    }
                }
                
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $darkMode)
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
        }
    }
}

#Preview {
    SettingsView()
} 
