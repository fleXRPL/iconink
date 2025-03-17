import SwiftUI
import CoreData

struct AddClientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = AddClientViewModel()
    @State private var showingIDScanner = false
    @State private var showingValidationAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Information")) {
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
                
                Section(header: Text("Identification")) {
                    HStack {
                        TextField("ID Type", text: $viewModel.idType)
                        
                        Button {
                            showingIDScanner = true
                        } label: {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    
                    TextField("ID Number", text: $viewModel.idNumber)
                    
                    DatePicker("ID Expiration Date", selection: $viewModel.idExpirationDate, displayedComponents: .date)
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add New Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if viewModel.validateInputs() {
                            viewModel.saveClient(context: viewContext)
                            dismiss()
                        } else {
                            showingValidationAlert = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingIDScanner) {
                Text("ID Scanner View - Coming Soon")
                    .padding()
            }
            .alert("Missing Information", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.validationErrorMessage)
            }
        }
    }
}

// MARK: - ViewModel
class AddClientViewModel: ObservableObject {
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @Published var idType: String = ""
    @Published var idNumber: String = ""
    @Published var idExpirationDate: Date = Calendar.current.date(byAdding: .year, value: 5, to: Date()) ?? Date()
    @Published var notes: String = ""
    
    var validationErrorMessage: String = ""
    
    func validateInputs() -> Bool {
        // First name and last name are required
        if firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrorMessage = "First name is required."
            return false
        }
        
        if lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrorMessage = "Last name is required."
            return false
        }
        
        // Validate email format if provided
        if !email.isEmpty {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            if !emailPredicate.evaluate(with: email) {
                validationErrorMessage = "Please enter a valid email address."
                return false
            }
        }
        
        // Validate phone format if provided
        if !phone.isEmpty {
            let phoneRegex = "^[+]?[(]?[0-9]{3}[)]?[-\\s.]?[0-9]{3}[-\\s.]?[0-9]{4,6}$"
            let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
            if !phonePredicate.evaluate(with: phone) {
                validationErrorMessage = "Please enter a valid phone number."
                return false
            }
        }
        
        // Validate ID information if ID type is provided
        if !idType.isEmpty {
            if idNumber.isEmpty {
                validationErrorMessage = "ID number is required when ID type is specified."
                return false
            }
            
            // Check if ID is expired
            if idExpirationDate < Date() {
                validationErrorMessage = "The ID has expired. Please provide a valid ID."
                return false
            }
        }
        
        return true
    }
    
    func saveClient(context: NSManagedObjectContext) {
        let client = Client(context: context)
        client.id = UUID()
        client.firstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        client.lastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        client.email = email.isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines)
        client.phone = phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines)
        client.dateOfBirth = dateOfBirth
        client.idType = idType.isEmpty ? nil : idType.trimmingCharacters(in: .whitespacesAndNewlines)
        client.idNumber = idNumber.isEmpty ? nil : idNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        client.idExpirationDate = idType.isEmpty ? nil : idExpirationDate
        client.notes = notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
        client.createdAt = Date()
        client.updatedAt = Date()
        
        do {
            try context.save()
        } catch {
            // Handle the error appropriately
            print("Error saving client: \(error.localizedDescription)")
        }
    }
}

#Preview {
    AddClientView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
