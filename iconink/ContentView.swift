import SwiftUI
import CoreData
import LocalAuthentication

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("useAuthenticationLock") private var useAuthenticationLock = false
    @State private var isUnlocked = false
    @State private var authError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Group {
            if useAuthenticationLock && !isUnlocked {
                // Lock screen
                VStack(spacing: 20) {
                    Image("IconInk_nobg")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                    
                    Text("IconInk")
                        .font(.largeTitle)
                        .bold()
                    
                    Button {
                        authenticate()
                    } label: {
                        Label("Unlock with Face ID", systemImage: "faceid")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    
                    if authError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .onAppear {
                    authenticate()
                }
            } else {
                // Main app content
                TabView {
                    NavigationStack {
                        ClientListView()
                    }
                    .tabItem {
                        Label("Clients", systemImage: "person.3")
                    }
                    
                    NavigationStack {
                        ConsentFormListView()
                    }
                    .tabItem {
                        Label("Forms", systemImage: "doc.text")
                    }
                    
                    NavigationStack {
                        ScannerView()
                    }
                    .tabItem {
                        Label("Scanner", systemImage: "doc.viewfinder")
                    }
                    
                    NavigationStack {
                        SettingsView()
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
        }
    }
    
    private func authenticate() {
        // Use the SecurityManager to handle authentication
        SecurityManager.shared.authenticateWithBiometrics(reason: "Unlock IconInk") { success, error in
            DispatchQueue.main.async {
                if success {
                    isUnlocked = true
                    authError = false
                } else {
                    authError = true
                    errorMessage = "Authentication failed: \(error?.localizedDescription ?? "Unknown error")"
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
