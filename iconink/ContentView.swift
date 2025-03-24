import SwiftUI
import CoreData
import LocalAuthentication

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var authManager = AuthenticationManager.shared
    
    var body: some View {
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
        .withAuthenticationLock()
        .onAppear {
            // Authenticate when app appears if locked
            if authManager.isLocked {
                authManager.authenticateUser()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
