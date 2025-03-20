import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        TabView {
            // Clients Tab
            NavigationStack {
                Text("Clients")
                    .font(.largeTitle)
                    .padding()
            }
            .tabItem {
                Label("Clients", systemImage: "person.3")
            }
            
            // Scanner Tab
            NavigationStack {
                Text("ID Scanner")
                    .font(.largeTitle)
                    .padding()
            }
            .tabItem {
                Label("Scanner", systemImage: "camera.viewfinder")
            }
            
            // Forms Tab
            NavigationStack {
                Text("Consent Forms")
                    .font(.largeTitle)
                    .padding()
            }
            .tabItem {
                Label("Forms", systemImage: "doc.text")
            }
            
            // Settings Tab
            NavigationStack {
                Text("Settings")
                    .font(.largeTitle)
                    .padding()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

// Simple preview without dependency on PersistenceController
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 
