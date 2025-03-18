import SwiftUI
import CoreData

struct ClientDetailView: View {
    let client: Client
    @State private var showingIDCamera = false
    @State private var showingSignature = false
    @State private var isCapturingFront = true
    
    var body: some View {
        List {
            Section("Personal Information") {
                LabeledContent("Name", value: client.fullName)
                if let phone = client.phone {
                    LabeledContent("Phone", value: phone)
                }
                if let email = client.email {
                    LabeledContent("Email", value: email)
                }
            }
            
            Section("ID Images") {
                Button {
                    isCapturingFront = true
                    showingIDCamera = true
                } label: {
                    if client.idFrontImage != nil {
                        Label("View Front of ID", systemImage: "photo")
                    } else {
                        Label("Capture Front of ID", systemImage: "camera")
                    }
                }
                
                Button {
                    isCapturingFront = false
                    showingIDCamera = true
                } label: {
                    if client.idBackImage != nil {
                        Label("View Back of ID", systemImage: "photo")
                    } else {
                        Label("Capture Back of ID", systemImage: "camera")
                    }
                }
            }
            
            Section("Signature") {
                Button {
                    showingSignature = true
                } label: {
                    if client.signature != nil {
                        Label("View Signature", systemImage: "signature")
                    } else {
                        Label("Capture Signature", systemImage: "signature")
                    }
                }
            }
            
            if let forms = client.consentForms, !forms.isEmpty {
                Section("Consent Forms") {
                    ForEach(Array(forms)) { form in
                        NavigationLink(form.title) {
                            ConsentFormDetailView(form: form)
                        }
                    }
                }
            }
        }
        .navigationTitle(client.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingIDCamera) {
            CameraView(isCapturingFront: isCapturingFront, client: client)
        }
        .sheet(isPresented: $showingSignature) {
            SignatureView(client: client)
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let client = Client(context: context)
    client.firstName = "John"
    client.lastName = "Doe"
    client.phone = "555-0123"
    client.email = "john@example.com"
    
    NavigationStack {
        ClientDetailView(client: client)
    }
    .environment(\.managedObjectContext, context)
} 
