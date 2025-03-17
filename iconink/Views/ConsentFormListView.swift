import SwiftUI
import CoreData

struct ConsentFormListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ConsentFormTemplate.title, ascending: true)],
        animation: .default)
    private var templates: FetchedResults<ConsentFormTemplate>
    
    @StateObject private var viewModel = ConsentFormListViewModel()
    @State private var showingAddTemplate = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Templates")) {
                    if templates.isEmpty {
                        Text("No templates available")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(filteredTemplates, id: \.self) { template in
                            NavigationLink {
                                ConsentFormTemplateDetailView(template: template)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.title ?? "Untitled Template")
                                        .fontWeight(.medium)
                                    
                                    Text(template.description ?? "No description")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteTemplates)
                    }
                }
                
                Section(header: Text("Recent Forms")) {
                    if viewModel.recentForms.isEmpty {
                        Text("No recent forms")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(viewModel.recentForms, id: \.self) { form in
                            NavigationLink {
                                Text("Consent Form Detail View - Coming Soon")
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(form.title ?? "Untitled Form")
                                        .fontWeight(.medium)
                                    
                                    if let client = form.client as? Client {
                                        Text("\(client.firstName ?? "") \(client.lastName ?? "")")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if let createdAt = form.createdAt {
                                        Text(createdAt, formatter: viewModel.dateFormatter)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Consent Forms")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTemplate = true
                    } label: {
                        Label("Add Template", systemImage: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search templates")
            .sheet(isPresented: $showingAddTemplate) {
                AddConsentFormTemplateView()
            }
            .onAppear {
                viewModel.loadRecentForms(context: viewContext)
            }
        }
    }
    
    private var filteredTemplates: [ConsentFormTemplate] {
        if searchText.isEmpty {
            return Array(templates)
        } else {
            return templates.filter { template in
                let title = template.title?.lowercased() ?? ""
                let description = template.description?.lowercased() ?? ""
                return title.contains(searchText.lowercased()) || 
                       description.contains(searchText.lowercased())
            }
        }
    }
    
    private func deleteTemplates(at offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredTemplates[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // Handle the error appropriately
                print("Error deleting template: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Template Detail View
struct ConsentFormTemplateDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var template: ConsentFormTemplate
    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false
    @State private var showingClientSelection = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isEditing {
                    editableTemplateContent
                } else {
                    templateContent
                }
            }
            .padding()
        }
        .navigationTitle(isEditing ? "Edit Template" : template.title ?? "Template Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    Button("Save") {
                        do {
                            try viewContext.save()
                            isEditing = false
                        } catch {
                            print("Error saving template: \(error.localizedDescription)")
                        }
                    }
                } else {
                    Menu {
                        Button {
                            showingClientSelection = true
                        } label: {
                            Label("Create Form", systemImage: "doc.badge.plus")
                        }
                        
                        Button {
                            isEditing = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            
            if isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewContext.rollback()
                        isEditing = false
                    }
                }
            }
        }
        .alert("Delete Template", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewContext.delete(template)
                do {
                    try viewContext.save()
                    dismiss()
                } catch {
                    print("Error deleting template: \(error.localizedDescription)")
                }
            }
        } message: {
            Text("Are you sure you want to delete this template? This action cannot be undone.")
        }
        .sheet(isPresented: $showingClientSelection) {
            Text("Client Selection View - Coming Soon")
        }
    }
    
    private var templateContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(template.title ?? "Untitled Template")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(template.description ?? "No description")
                .foregroundColor(.secondary)
            
            Divider()
            
            Text("Template Content")
                .font(.headline)
                .padding(.bottom, 4)
            
            Text(template.content ?? "No content")
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            
            if let createdAt = template.createdAt {
                Divider()
                
                Text("Created: \(createdAt, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let updatedAt = template.updatedAt, updatedAt != template.createdAt {
                Text("Last Updated: \(updatedAt, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var editableTemplateContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Title", text: Binding(
                get: { template.title ?? "" },
                set: { template.title = $0 }
            ))
            .font(.title2)
            .fontWeight(.bold)
            
            TextField("Description", text: Binding(
                get: { template.description ?? "" },
                set: { template.description = $0 }
            ))
            .foregroundColor(.secondary)
            
            Divider()
            
            Text("Template Content")
                .font(.headline)
                .padding(.bottom, 4)
            
            TextEditor(text: Binding(
                get: { template.content ?? "" },
                set: { 
                    template.content = $0
                    template.updatedAt = Date()
                }
            ))
            .frame(minHeight: 300)
            .padding(10)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Add Template View
struct AddConsentFormTemplateView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var content = ""
    @State private var showingValidationAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Template Information")) {
                    TextField("Title", text: $title)
                    
                    TextField("Description", text: $description)
                }
                
                Section(header: Text("Template Content")) {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if validateInputs() {
                            saveTemplate()
                            dismiss()
                        } else {
                            showingValidationAlert = true
                        }
                    }
                }
            }
            .alert("Missing Information", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please provide a title and content for the template.")
            }
        }
    }
    
    private func validateInputs() -> Bool {
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveTemplate() {
        let template = ConsentFormTemplate(context: viewContext)
        template.id = UUID()
        template.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        template.description = description.isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines)
        template.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        template.createdAt = Date()
        template.updatedAt = Date()
        
        do {
            try viewContext.save()
        } catch {
            // Handle the error appropriately
            print("Error saving template: \(error.localizedDescription)")
        }
    }
}

// MARK: - ViewModel
class ConsentFormListViewModel: ObservableObject {
    @Published var recentForms: [ConsentForm] = []
    
    let dateFormatter: DateFormatter
    
    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
    }
    
    func loadRecentForms(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<ConsentForm> = ConsentForm.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ConsentForm.createdAt, ascending: false)]
        fetchRequest.fetchLimit = 5
        
        do {
            recentForms = try context.fetch(fetchRequest)
        } catch {
            print("Error fetching recent forms: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ConsentFormListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
