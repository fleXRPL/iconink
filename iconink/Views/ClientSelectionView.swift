import SwiftUI
import CoreData

struct ClientSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    let onSelectClient: (Client) -> Void
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.name, ascending: true)],
        animation: .default)
    private var clients: FetchedResults<Client>
    
    var filteredClients: [Client] {
        if searchText.isEmpty {
            return Array(clients)
        }
        return clients.filter { $0.fullName.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredClients) { client in
                    Button {
                        onSelectClient(client)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading) {
                            Text(client.fullName)
                                .font(.headline)
                            if let email = client.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search clients")
            .navigationTitle("Select Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        AddClientView()
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
        }
    }
}
