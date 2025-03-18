import SwiftUI
import CoreData

struct ConsentFormListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ConsentForm.dateCreated, ascending: false)],
        animation: .default)
    private var forms: FetchedResults<ConsentForm>
    
    var body: some View {
        List {
            ForEach(forms) { form in
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
        .navigationTitle("Consent Forms")
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
