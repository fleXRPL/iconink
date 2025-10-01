import SwiftUI
import CoreData

struct ClientListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddClient = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.lastName, ascending: true)],
        animation: .default)
    private var clients: FetchedResults<Client>
    
    var body: some View {
        List {
            ForEach(clients) { client in
                NavigationLink {
                    ClientDetailView(client: client)
                } label: {
                    VStack(alignment: .leading) {
                        Text(client.fullName)
                            .font(.headline)
                        if let phone = client.phone {
                            Text(phone)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .onDelete(perform: deleteClients)
        }
        .navigationTitle("Clients")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddClient = true
                } label: {
                    Label("Add Client", systemImage: "person.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showingAddClient) {
            AddClientView()
        }
    }
    
    private func deleteClients(offsets: IndexSet) {
        withAnimation {
            offsets.map { clients[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting client: \(error)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        ClientListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 
