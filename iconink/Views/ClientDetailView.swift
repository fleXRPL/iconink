import SwiftUI
import CoreData

struct ClientDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var client: Client
    @StateObject private var viewModel: ClientDetailViewModel
    @State private var isEditMode: Bool = false
    @State private var showingDeleteConfirmation = false
    
    init(client: Client) {
        self.client = client
        _viewModel = StateObject(wrappedValue: ClientDetailViewModel(client: client))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                clientHeader
                
                Divider()
                
                if isEditMode {
                    editableClientDetails
                } else {
                    clientDetails
                }
                
                Divider()
                
                consentFormsSection
                
                Divider()
                
                notesSection
            }
            .padding()
        }
        .navigationTitle(isEditMode ? "Edit Client" : "Client Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditMode {
                    Button("Save") {
                        viewModel.saveChanges(context: viewContext)
                        isEditMode = false
                    }
                } else {
                    Menu {
                        Button {
                            isEditMode = true
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
            
            if isEditMode {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.resetChanges()
                        isEditMode = false
                    }
                }
            }
        }
        .alert("Delete Client", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteClient(context: viewContext)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this client? This action cannot be undone.")
        }
    }
    
    private var clientHeader: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 70, height: 70)
                
                Text(viewModel.initials)
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(client.firstName ?? "") \(client.lastName ?? "")")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let dateOfBirth = client.dateOfBirth {
                    Text("DOB: \(dateOfBirth, formatter: viewModel.dateFormatter)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("Client ID: \(client.id?.uuidString.prefix(8) ?? "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var clientDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personal Information")
                .font(.headline)
            
            detailRow(title: "Email", value: client.email ?? "Not provided")
            detailRow(title: "Phone", value: client.phone ?? "Not provided")
            
            if let idType = client.idType, !idType.isEmpty {
                detailRow(title: "ID Type", value: idType)
                detailRow(title: "ID Number", value: client.idNumber ?? "Not provided")
                
                if let idExpirationDate = client.idExpirationDate {
                    detailRow(title: "ID Expiration", value: idExpirationDate, formatter: viewModel.dateFormatter)
                }
            }
            
            if let createdAt = client.createdAt {
                detailRow(title: "Client Since", value: createdAt, formatter: viewModel.dateFormatter)
            }
        }
    }
    
    private var editableClientDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personal Information")
                .font(.headline)
            
            Group {
                TextField("First Name", text: $viewModel.firstName)
                    .textContentType(.givenName)
                
                TextField("Last Name", text: $viewModel.lastName)
                    .textContentType(.familyName)
                
                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                TextField("Phone", text: $viewModel.phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                
                DatePicker("Date of Birth", selection: $viewModel.dateOfBirth, displayedComponents: .date)
            }
            .padding(10)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
            
            Text("Identification")
                .font(.headline)
                .padding(.top, 8)
            
            Group {
                TextField("ID Type", text: $viewModel.idType)
                
                TextField("ID Number", text: $viewModel.idNumber)
                
                DatePicker("ID Expiration Date", selection: $viewModel.idExpirationDate, displayedComponents: .date)
            }
            .padding(10)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private var consentFormsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Consent Forms")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink {
                    Text("Add Consent Form View - Coming Soon")
                } label: {
                    Label("Add", systemImage: "plus.circle")
                        .font(.subheadline)
                }
            }
            
            if let consentForms = client.consentForms, consentForms.isEmpty {
                Text("No consent forms")
                    .italic()
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                if let forms = consentForms as? Set<ConsentForm> {
                    ForEach(forms, id: \.self) { form in
                        NavigationLink {
                            Text("Consent Form Detail View - Coming Soon")
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(form.title ?? "Untitled Form")
                                        .fontWeight(.medium)
                                    
                                    if let createdAt = form.createdAt {
                                        Text(createdAt, formatter: viewModel.dateFormatter)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                } else {
                    // Handle error case
                }
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
            
            if isEditMode {
                TextEditor(text: $viewModel.notes)
                    .frame(minHeight: 100)
                    .padding(10)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
            } else {
                Text(client.notes ?? "No notes")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
    
    private func detailRow<T>(title: String, value: T, formatter: Formatter) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value, formatter: formatter)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ViewModel
class ClientDetailViewModel: ObservableObject {
    @Published var firstName: String
    @Published var lastName: String
    @Published var email: String
    @Published var phone: String
    @Published var dateOfBirth: Date
    @Published var idType: String
    @Published var idNumber: String
    @Published var idExpirationDate: Date
    @Published var notes: String
    
    private let client: Client
    let dateFormatter: DateFormatter
    
    var initials: String {
        let firstInitial = firstName.first?.uppercased() ?? ""
        let lastInitial = lastName.first?.uppercased() ?? ""
        return "\(firstInitial)\(lastInitial)"
    }
    
    init(client: Client) {
        self.client = client
        self.firstName = client.firstName ?? ""
        self.lastName = client.lastName ?? ""
        self.email = client.email ?? ""
        self.phone = client.phone ?? ""
        self.dateOfBirth = client.dateOfBirth ?? Date()
        self.idType = client.idType ?? ""
        self.idNumber = client.idNumber ?? ""
        self.idExpirationDate = client.idExpirationDate ?? Date()
        self.notes = client.notes ?? ""
        
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateStyle = .medium
        self.dateFormatter.timeStyle = .none
    }
    
    func resetChanges() {
        firstName = client.firstName ?? ""
        lastName = client.lastName ?? ""
        email = client.email ?? ""
        phone = client.phone ?? ""
        dateOfBirth = client.dateOfBirth ?? Date()
        idType = client.idType ?? ""
        idNumber = client.idNumber ?? ""
        idExpirationDate = client.idExpirationDate ?? Date()
        notes = client.notes ?? ""
    }
    
    func saveChanges(context: NSManagedObjectContext) {
        client.firstName = firstName
        client.lastName = lastName
        client.email = email
        client.phone = phone
        client.dateOfBirth = dateOfBirth
        client.idType = idType
        client.idNumber = idNumber
        client.idExpirationDate = idExpirationDate
        client.notes = notes
        client.updatedAt = Date()
        
        do {
            try context.save()
        } catch {
            // Handle the error appropriately
            print("Error saving client: \(error.localizedDescription)")
        }
    }
    
    func deleteClient(context: NSManagedObjectContext) {
        context.delete(client)
        
        do {
            try context.save()
        } catch {
            // Handle the error appropriately
            print("Error deleting client: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let previewContext = PersistenceController.preview.container.viewContext
    let client = Client(context: previewContext)
    client.id = UUID()
    client.firstName = "John"
    client.lastName = "Doe"
    client.email = "john.doe@example.com"
    client.phone = "(555) 123-4567"
    client.dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())
    client.idType = "Driver's License"
    client.idNumber = "DL12345678"
    client.idExpirationDate = Calendar.current.date(byAdding: .year, value: 5, to: Date())
    client.notes = "Client prefers appointments in the afternoon. Allergic to certain inks."
    client.createdAt = Date()
    client.updatedAt = Date()
    
    return NavigationStack {
        ClientDetailView(client: client)
            .environment(\.managedObjectContext, previewContext)
    }
} 
