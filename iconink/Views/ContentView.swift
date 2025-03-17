import SwiftUI

struct ContentView: View {
    @State private var searchResults = [String]()

    var body: some View {
        if searchResults.isEmpty {
            Text("No results found")
        }
    }
}

enum Tab {
    case forms
    case clients
    case scan
    case settings
} 
