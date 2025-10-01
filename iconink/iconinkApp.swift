import SwiftUI
import CoreData

@main
struct IconInkApp: App {
    @StateObject private var persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationView {
            VStack {
                Text("IconInk")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Tattoo & Piercing Client Management")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
                
                VStack(spacing: 20) {
                    Text("Welcome to IconInk")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Your local-only client management solution for tattoo and piercing professionals.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                Text("Version 1.0 - MVP")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
            .navigationTitle("IconInk")
        }
    }
}
