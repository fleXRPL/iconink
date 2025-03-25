import SwiftUI
import CoreData
import LocalAuthentication

// MARK: - Authentication Manager
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLocked = false
    
    static let shared = AuthenticationManager()
    
    func authenticateWithBiometrics(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to unlock the app"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(true, nil)
                    } else {
                        completion(false, error)
                    }
                }
            }
        } else {
            completion(false, error)
        }
    }
}

// MARK: - Authentication View Modifier
extension View {
    func withAuthenticationLock(isLocked: Bool, authenticate: @escaping () -> Void) -> some View {
        self.overlay(
            Group {
                if isLocked {
                    ZStack {
                        Color(.systemBackground).edgesIgnoringSafeArea(.all)
                        VStack {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 60))
                                .padding()
                            Text("App Locked")
                                .font(.title)
                                .padding()
                            Button("Unlock with Face ID / Touch ID") {
                                authenticate()
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        )
    }
}

// ContentView serves as a placeholder for the actual content
struct ContentView: View {
    var body: some View {
        TabView {
            NavigationView {
                Text("Clients")
                    .navigationTitle("Clients")
            }
            .tabItem {
                Label("Clients", systemImage: "person.2")
            }
            
            NavigationView {
                Text("Forms")
                    .navigationTitle("Forms")
            }
            .tabItem {
                Label("Forms", systemImage: "doc.text")
            }
            
            NavigationView {
                Text("Scanner")
                    .navigationTitle("Scanner")
            }
            .tabItem {
                Label("Scanner", systemImage: "camera")
            }
            
            NavigationView {
                Text("Settings")
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

@main
struct IconInkApp: App {
    @StateObject private var persistenceController = PersistenceController.shared
    @StateObject private var authManager = AuthenticationManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .withAuthenticationLock(isLocked: authManager.isLocked) {
                    authManager.authenticateWithBiometrics { success, _ in
                        if success {
                            authManager.isLocked = false
                        }
                    }
                }
                .onAppear {
                    if authManager.isLocked {
                        authManager.authenticateWithBiometrics { success, _ in
                            if success {
                                authManager.isLocked = false
                            }
                        }
                    }
                }
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
