import SwiftUI
import PDFKit
import CoreData

struct ConsentFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let client: Client
    let formType: ConsentFormType
    
    @StateObject private var viewModel = ConsentFormViewModel()
    @State private var showingSignatureCapture = false
    @State private var showingPreview = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                // Form type section
                Section(header: Text("Form Type")) {
                    Text(formType.rawValue)
                        .foregroundColor(.secondary)
                }
                
                // Client information section
                Section(header: Text("Client Information")) {
                    TextField("Name", text: $viewModel.fields.clientName)
                    TextField("Email", text: $viewModel.fields.email)
                    TextField("Phone", text: $viewModel.fields.phone)
                    TextField("Address", text: $viewModel.fields.address)
                }
                
                // Form specific fields
                formSpecificFields
                
                // Signature section
                Section(header: Text("Signature")) {
                    if viewModel.signature == nil {
                        Button(action: { showingSignatureCapture = true }) {
                            Label("Add Signature", systemImage: "signature")
                        }
                    } else {
                        VStack(alignment: .leading) {
                            Text("Signature Added")
                                .foregroundColor(.green)
                            Button("Change", action: { showingSignatureCapture = true })
                        }
                    }
                }
                
                // Preview and generate buttons
                Section {
                    Button(action: { showingPreview = true }) {
                        Label("Preview Form", systemImage: "doc.text.magnifyingglass")
                    }
                    
                    Button(action: generateForm) {
                        Label("Generate Form", systemImage: "doc.badge.plus")
                    }
                    .disabled(!viewModel.isValid)
                }
            }
            .navigationTitle("New Consent Form")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
            .sheet(isPresented: $showingSignatureCapture) {
                SignatureCaptureView(client: client, consentForm: nil) { signature in
                    viewModel.signature = signature
                }
            }
            .sheet(isPresented: $showingPreview) {
                if let previewImage = viewModel.previewImage {
                    PDFPreviewView(image: previewImage) {
                        showingPreview = false
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                viewModel.initializeFields(with: client, formType: formType)
            }
        }
    }
    
    private var formSpecificFields: some View {
        Group {
            switch formType {
            case .tattoo:
                Section(header: Text("Tattoo Details")) {
                    TextField("Design Description", text: $viewModel.fields.designDescription)
                    TextField("Body Location", text: $viewModel.fields.bodyLocation)
                    TextField("Artist Name", text: $viewModel.fields.artistName)
                }
                
            case .piercing:
                Section(header: Text("Piercing Details")) {
                    TextField("Piercing Location", text: $viewModel.fields.piercingLocation)
                    TextField("Jewelry Type", text: $viewModel.fields.jewelryType)
                    TextField("Piercer Name", text: $viewModel.fields.piercerName)
                }
                
            case .minorConsent:
                Section(header: Text("Guardian Details")) {
                    TextField("Guardian Name", text: $viewModel.fields.guardianName)
                    TextField("Relationship", text: $viewModel.fields.relationship)
                    TextField("Guardian ID", text: $viewModel.fields.guardianID)
                }
                
            case .medicalHistory:
                Section(header: Text("Medical Information")) {
                    TextField("Allergies", text: $viewModel.fields.allergies)
                    TextField("Medications", text: $viewModel.fields.medications)
                    TextField("Medical Conditions", text: $viewModel.fields.medicalConditions)
                }
                
            case .aftercare:
                Section(header: Text("Procedure Details")) {
                    TextField("Procedure Type", text: $viewModel.fields.procedureType)
                    TextField("Artist Name", text: $viewModel.fields.artistName)
                }
            }
        }
    }
    
    private func generateForm() {
        viewModel.generateForm(in: viewContext, for: client) { result in
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

class ConsentFormViewModel: ObservableObject {
    @Published var fields = FormFields()
    @Published var signature: Signature?
    @Published var previewImage: UIImage?
    @Published var isValid = false
    
    private var formType: ConsentFormType?
    
    func initializeFields(with client: Client, formType: ConsentFormType) {
        self.formType = formType
        
        // Initialize fields with client data
        fields.clientName = client.name ?? ""
        fields.email = client.email ?? ""
        fields.phone = client.phone ?? ""
        fields.address = client.address ?? ""
        
        validateFields()
        updatePreview()
    }
    
    func generateForm(
        in context: NSManagedObjectContext,
        for client: Client,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let formType = formType else {
            completion(.failure(PDFGenerationError.invalidData))
            return
        }
        
        // Convert fields to dictionary
        let fieldDict = fields.toDictionary()
        
        // Generate PDF
        let result = PDFGenerator.shared.generateConsentForm(
            type: formType,
            fields: fieldDict,
            signature: signature?.exportAsImage().success
        )
        
        switch result {
        case .success(let pdfData):
            // Create consent form
            let form = ConsentForm(context: context)
            form.id = UUID()
            form.title = formType.rawValue
            form.content = fieldDict.description
            form.createdAt = Date()
            form.type = formType.rawValue
            form.pdfData = pdfData
            form.client = client
            form.signature = signature
            
            do {
                try context.save()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
            
        case .failure(let error):
            completion(.failure(error))
        }
    }
    
    private func validateFields() {
        guard let formType = formType else {
            isValid = false
            return
        }
        
        let template = ConsentFormTemplateManager.shared.template(for: formType)
        isValid = template.validate(fields: fields.toDictionary())
    }
    
    private func updatePreview() {
        guard let formType = formType else { return }
        
        previewImage = PDFGenerator.shared.createPreview(
            type: formType,
            fields: fields.toDictionary(),
            signature: signature?.exportAsImage().success
        )
    }
}

struct FormFields {
    // Common fields
    var clientName = ""
    var email = ""
    var phone = ""
    var address = ""
    
    // Tattoo fields
    var designDescription = ""
    var bodyLocation = ""
    var artistName = ""
    
    // Piercing fields
    var piercingLocation = ""
    var jewelryType = ""
    var piercerName = ""
    
    // Minor consent fields
    var guardianName = ""
    var relationship = ""
    var guardianID = ""
    
    // Medical history fields
    var allergies = ""
    var medications = ""
    var medicalConditions = ""
    
    // Aftercare fields
    var procedureType = ""
    
    func toDictionary() -> [String: String] {
        var dict = [String: String]()
        
        // Add non-empty fields
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let key = child.label,
               let value = child.value as? String,
               !value.isEmpty {
                dict[key] = value
            }
        }
        
        // Add current date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dict["date"] = dateFormatter.string(from: Date())
        
        return dict
    }
}

struct PDFPreviewView: View {
    let image: UIImage
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
            }
            .navigationBarTitle("Preview", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                onDismiss()
            })
        }
    }
}

#Preview {
    ConsentFormView(
        client: Client(),
        formType: .tattoo
    )
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 