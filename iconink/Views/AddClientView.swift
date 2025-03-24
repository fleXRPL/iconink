import SwiftUI
import CoreData

struct AddClientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    
    var body: some View {
        Form {
            Section("Personal Information") {
                TextField("First Name", text: $firstName)
                    .textContentType(.givenName)
                TextField("Last Name", text: $lastName)
                    .textContentType(.familyName)
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                TextField("Phone", text: $phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            }
        }
        .navigationTitle("New Client")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveClient()
                }
                .disabled(firstName.isEmpty || lastName.isEmpty)
            }
        }
    }
    
    private func saveClient() {
        let client = Client(context: viewContext)
        client.id = UUID()
        client.name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        client.email = email.isEmpty ? nil : email
        client.phone = phone.isEmpty ? nil : phone
        client.createdAt = Date()
        client.updatedAt = Date()
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving client: \(error)")
        }
    }
}

#Preview {
    AddClientView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
