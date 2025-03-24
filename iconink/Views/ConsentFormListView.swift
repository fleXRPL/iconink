import SwiftUI
import CoreData

struct ConsentFormListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingClientSelection = false
    @State private var searchText = ""
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ConsentForm.dateCreated, ascending: false)],
        animation: .default)
    private var forms: FetchedResults<ConsentForm>
    
    var filteredForms: [ConsentForm] {
        if searchText.isEmpty {
            return Array(forms)
        }
        return forms.filter { form in
            form.title.localizedCaseInsensitiveContains(searchText) ||
            (form.client?.fullName.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredForms) { form in
                NavigationLink {
                    ConsentFormDetailView(form: form)
                } label: {
                    VStack(alignment: .leading) {
                        Text(form.title)
                            .font(.headline)
                        Text(form.client?.fullName ?? "No Client")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteForms)
        }
        .searchable(text: $searchText, prompt: "Search forms")
        .navigationTitle("Consent Forms")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingClientSelection = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingClientSelection) {
            ClientSelectionView { client in
                NavigationStack {
                    NewConsentFormView(client: client)
                }
            }
        }
    }
    
    private func deleteForms(offsets: IndexSet) {
        withAnimation {
            offsets.map { forms[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting form: \(error)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        ConsentFormListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
