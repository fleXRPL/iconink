import SwiftUI
import CoreData

struct NewConsentFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let client: Client
    
    @State private var selectedFormType: ConsentFormType = .tattoo
    @State private var showingFormCreation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Client information
                VStack(alignment: .leading, spacing: 8) {
                    Text("Client: \(client.fullName)")
                        .font(.headline)
                    if let email = client.email {
                        Text("Email: \(email)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    if let phone = client.phone {
                        Text("Phone: \(phone)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Form type selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Form Type")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(ConsentFormType.allCases, id: \.self) { formType in
                        Button(action: {
                            selectedFormType = formType
                            showingFormCreation = true
                        }) {
                            HStack {
                                Image(systemName: formType.icon)
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading) {
                                    Text(formType.rawValue)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(formType.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 1)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("New Consent Form")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingFormCreation) {
                ConsentFormView(client: client, formType: selectedFormType)
            }
        }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let client = Client(context: context)
    client.name = "John Doe"
    
    return NewConsentFormView(client: client)
        .environment(\.managedObjectContext, context)
}
