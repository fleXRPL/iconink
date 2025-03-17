import SwiftUI
import CoreData
import VisionKit

struct ConsentFormEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: ConsentFormEditViewModel
    @State private var showingDiscardAlert = false
    @State private var showingValidationAlert = false
    @State private var showingIDScanner = false
    @State private var scanningError: String?
    @State private var showingScanningError = false
    
    init(consentForm: ConsentForm? = nil) {
        _viewModel = StateObject(wrappedValue: ConsentFormEditViewModel(consentForm: consentForm))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: viewModel.completionProgress)
                    .tint(.accentColor)
                    .padding()
                
                Form {
                    // Step 1: Basic Information
                    Section {
                        TextField("Form Title", text: $viewModel.formTitle)
                        
                        Picker("Form Type", selection: $viewModel.formType) {
                            Text("Tattoo").tag(0)
                            Text("Piercing").tag(1)
                            Text("Other").tag(2)
                        }
                        
                        DatePicker("Service Date", selection: $viewModel.serviceDate, displayedComponents: .date)
                    } header: {
                        HStack {
                            Image(systemName: "1.circle.fill")
                            Text("Basic Information")
                        }
                    }
                    
                    // Step 2: Client Information
                    Section {
                        if viewModel.hasClientInfo {
                            clientInfoView
                        } else {
                            Button(action: { showingIDScanner = true }) {
                                HStack {
                                    Image(systemName: "camera.viewfinder")
                                    Text("Scan Client ID")
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "2.circle.fill")
                            Text("Client Information")
                        }
                    }
                    
                    // Step 3: Service Details
                    Section {
                        TextEditor(text: $viewModel.serviceDescription)
                            .frame(minHeight: 100)
                    } header: {
                        HStack {
                            Image(systemName: "3.circle.fill")
                            Text("Service Description")
                        }
                    }
                    
                    // Step 4: Aftercare Instructions
                    Section {
                        TextEditor(text: $viewModel.aftercareInstructions)
                            .frame(minHeight: 100)
                    } header: {
                        HStack {
                            Image(systemName: "4.circle.fill")
                            Text("Aftercare Instructions")
                        }
                    }
                    
                    // Step 5: Risk Acknowledgments
                    Section {
                        ForEach(viewModel.standardRisks, id: \.self) { risk in
                            Toggle(risk, isOn: viewModel.bindingForRisk(risk))
                        }
                        
                        if !viewModel.customRisks.isEmpty {
                            ForEach(viewModel.customRisks, id: \.self) { risk in
                                Toggle(risk, isOn: viewModel.bindingForRisk(risk))
                            }
                        }
                        
                        Button(action: viewModel.addCustomRisk) {
                            Label("Add Custom Risk", systemImage: "plus.circle")
                        }
                        
                        TextEditor(text: $viewModel.additionalAcknowledgments)
                            .frame(minHeight: 100)
                    } header: {
                        HStack {
                            Image(systemName: "5.circle.fill")
                            Text("Risk Acknowledgments")
                        }
                    }
                    
                    // Step 6: Signatures
                    Section {
                        if viewModel.hasRequiredSignatures {
                            ForEach(viewModel.signatures) { signature in
                                SignatureRow(signature: signature)
                            }
                        }
                        
                        NavigationLink {
                            SignatureView(signatureType: viewModel.nextRequiredSignatureType) { signature in
                                viewModel.addSignature(signature)
                            }
                        } label: {
                            Label("Add \(viewModel.nextRequiredSignatureType.rawValue) Signature", 
                                  systemImage: "signature")
                        }
                        .disabled(viewModel.hasAllSignatures)
                    } header: {
                        HStack {
                            Image(systemName: "6.circle.fill")
                            Text("Required Signatures")
                        }
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Form" : "New Form")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if viewModel.hasUnsavedChanges {
                            showingDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if viewModel.validateForm() {
                            viewModel.saveForm(context: viewContext)
                            dismiss()
                        } else {
                            showingValidationAlert = true
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .alert("Discard Changes", isPresented: $showingDiscardAlert, actions: {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            }, message: {
                Text("Are you sure you want to discard your changes?")
            })
            .alert("Incomplete Form", isPresented: $showingValidationAlert, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(viewModel.validationMessage)
            })
            .alert("Scanning Error", isPresented: $showingScanningError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(scanningError ?? "Unknown error occurred")
            }
            .sheet(isPresented: $showingIDScanner) {
                IDScannerView { result in
                    switch result {
                    case .success(let clientInfo):
                        viewModel.updateClientInfo(with: clientInfo)
                    case .failure(let error):
                        scanningError = error.localizedDescription
                        showingScanningError = true
                    }
                }
            }
        }
    }
    
    private var clientInfoView: some View {
        VStack(alignment: .leading) {
            Text(viewModel.clientName)
                .font(.headline)
            
            if let dob = viewModel.clientDateOfBirth {
                Text("DOB: \(dob.formatted(date: .long, time: .omitted))")
                    .font(.subheadline)
            }
            
            if let idInfo = viewModel.clientIDInfo {
                Text(idInfo)
                    .font(.subheadline)
            }
            
            Button(action: { showingIDScanner = true }) {
                Text("Scan New ID")
                    .font(.subheadline)
            }
        }
    }
}

// MARK: - Supporting Views

struct SignatureRow: View {
    let signature: SignatureInfo
    
    var body: some View {
        HStack {
            Image(uiImage: signature.image)
                .resizable()
                .scaledToFit()
                .frame(height: 60)
            
            VStack(alignment: .leading) {
                Text(signature.type.rawValue)
                    .font(.headline)
                Text(signature.date.formatted(date: .long, time: .shortened))
                    .font(.caption)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ConsentFormEditView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

// MARK: - ViewModel

class ConsentFormEditViewModel: ObservableObject {
    private let existingForm: ConsentForm?
    
    @Published var formTitle: String = ""
    @Published var serviceDate: Date = Date()
    @Published var formType: Int16 = 0
    @Published var selectedClient: Client?
    @Published var serviceDescription: String = ""
    @Published var aftercareInstructions: String = ""
    @Published var selectedRisks: Set<String> = []
    @Published var customRisks: [String] = []
    @Published var additionalAcknowledgments: String = ""
    @Published var signatures: [SignatureInfo] = []
    @Published var validationMessage: String = ""
    
    var isEditing: Bool { existingForm != nil }
    
    let standardRisks = [
        "I understand that tattoos/piercings are permanent body modifications",
        "I acknowledge the risks of infection if aftercare instructions are not followed",
        "I confirm I am not under the influence of alcohol or drugs",
        "I understand that the healing process varies by individual",
        "I acknowledge that touch-ups may be needed",
        "I confirm I have no known allergies to the materials used"
    ]
    
    init(consentForm: ConsentForm? = nil) {
        self.existingForm = consentForm
        
        if let form = consentForm {
            loadExistingForm(form)
        }
    }
    
    // MARK: - Computed Properties
    
    var completionProgress: Double {
        var progress = 0.0
        let totalSteps = 6.0 // Total number of form sections
        
        // Step 1: Basic Information
        if !formTitle.isEmpty { progress += 1 }
        
        // Step 2: Client Information
        if hasClientInfo { progress += 1 }
        
        // Step 3: Service Description
        if !serviceDescription.isEmpty { progress += 1 }
        
        // Step 4: Aftercare Instructions
        if !aftercareInstructions.isEmpty { progress += 1 }
        
        // Step 5: Risk Acknowledgments
        if !selectedRisks.isEmpty { progress += 1 }
        
        // Step 6: Signatures
        if hasRequiredSignatures { progress += 1 }
        
        return progress / totalSteps
    }
    
    var hasClientInfo: Bool {
        selectedClient != nil
    }
    
    var clientName: String {
        guard let client = selectedClient else { return "" }
        return client.fullName
    }
    
    var clientDateOfBirth: Date? {
        selectedClient?.dateOfBirth
    }
    
    var clientIDInfo: String? {
        guard let client = selectedClient,
              let idNumber = client.idNumber,
              let expDate = client.idExpirationDate else { return nil }
        
        var info = "ID: \(idNumber)"
        if let state = client.idState {
            info += " (\(state))"
        }
        info += "\nExpires: \(expDate.formatted(date: .long, time: .omitted))"
        
        if client.isMinor {
            info += "\n⚠️ Minor - Requires Parental Consent"
        }
        
        return info
    }
    
    var hasRequiredSignatures: Bool {
        !signatures.isEmpty
    }
    
    var hasAllSignatures: Bool {
        let requiredTypes: Set<SignatureType> = [.client]
        if let client = selectedClient, client.isMinor {
            requiredTypes.insert(.parent)
        }
        let existingTypes = Set(signatures.map { $0.type })
        return existingTypes.isSuperset(of: requiredTypes)
    }
    
    var nextRequiredSignatureType: SignatureType {
        if !signatures.contains(where: { $0.type == .client }) {
            return .client
        }
        if let client = selectedClient,
           client.isMinor && !signatures.contains(where: { $0.type == .parent }) {
            return .parent
        }
        return .client
    }
    
    var canSave: Bool {
        !formTitle.isEmpty &&
        hasClientInfo &&
        !serviceDescription.isEmpty &&
        !selectedRisks.isEmpty &&
        hasRequiredSignatures
    }
    
    // MARK: - Methods
    
    func loadExistingForm(_ form: ConsentForm) {
        formTitle = form.formTitle ?? ""
        serviceDate = form.serviceDate ?? Date()
        formType = form.formType
        selectedClient = form.client
        serviceDescription = form.serviceDescription ?? ""
        aftercareInstructions = form.aftercareInstructions ?? ""
        loadAcknowledgedRisks(from: form)
        additionalAcknowledgments = form.additionalAcknowledgments ?? ""
        loadSignatures(from: form)
    }
    
    private func loadAcknowledgedRisks(from form: ConsentForm) {
        guard let risksJSON = form.acknowledgedRisksJSON,
              let data = risksJSON.data(using: .utf8),
              let risks = try? JSONDecoder().decode([String].self, from: data) else {
            return
        }
        
        selectedRisks = Set(risks.filter { standardRisks.contains($0) })
        customRisks = risks.filter { !standardRisks.contains($0) }
    }
    
    private func loadSignatures(from form: ConsentForm) {
        guard let signatureSet = form.signatures as? Set<Signature> else { return }
        signatures = signatureSet.compactMap { signature in
            guard let image = signature.loadSignature(),
                  let type = SignatureType(rawValue: signature.type) else { return nil }
            return SignatureInfo(type: type, image: image, date: signature.captureDate ?? Date())
        }
    }
    
    func bindingForRisk(_ risk: String) -> Binding<Bool> {
        Binding(
            get: { self.selectedRisks.contains(risk) },
            set: { isSelected in
                if isSelected {
                    self.selectedRisks.insert(risk)
                } else {
                    self.selectedRisks.remove(risk)
                }
            }
        )
    }
    
    func addCustomRisk() {
        // Show alert or sheet to add custom risk
        let newRisk = "Custom Risk \(customRisks.count + 1)"
        customRisks.append(newRisk)
        selectedRisks.insert(newRisk)
    }
    
    func updateClientInfo(with info: ClientInfo) {
        let context = PersistenceController.shared.container.viewContext
        let client = Client(context: context)
        
        client.firstName = info.firstName
        client.lastName = info.lastName
        client.dateOfBirth = info.dateOfBirth
        client.idNumber = info.idNumber
        client.idExpirationDate = info.idExpirationDate
        client.idState = info.idState
        client.createdAt = Date()
        client.updatedAt = Date()
        
        if let dob = info.dateOfBirth {
            let age = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
            client.isMinor = age < 18
            client.hasParentalConsent = false
        }
        
        do {
            try context.save()
            self.selectedClient = client
        } catch {
            print("Error saving client: \(error)")
        }
    }
    
    func addSignature(_ signature: SignatureInfo) {
        signatures.append(signature)
    }
    
    func validateForm() -> Bool {
        if formTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = "Please enter a form title"
            return false
        }
        
        if selectedClient == nil {
            validationMessage = "Please scan a client ID"
            return false
        }
        
        if serviceDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = "Please enter a service description"
            return false
        }
        
        if selectedRisks.isEmpty {
            validationMessage = "Please acknowledge at least one risk"
            return false
        }
        
        if !hasRequiredSignatures {
            validationMessage = "Please collect all required signatures"
            return false
        }
        
        return true
    }
    
    func saveForm(context: NSManagedObjectContext) {
        let form = existingForm ?? ConsentForm(context: context)
        
        form.formTitle = formTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        form.serviceDate = serviceDate
        form.formType = formType
        form.client = selectedClient
        form.serviceDescription = serviceDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        form.aftercareInstructions = aftercareInstructions.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Save risks
        let allRisks = Array(selectedRisks)
        if let risksData = try? JSONEncoder().encode(allRisks) {
            form.acknowledgedRisksJSON = String(data: risksData, encoding: .utf8)
        }
        
        form.additionalAcknowledgments = additionalAcknowledgments.trimmingCharacters(in: .whitespacesAndNewlines)
        form.formStatus = hasAllSignatures ? 2 : 1
        form.updatedAt = Date()
        
        if form.createdAt == nil {
            form.createdAt = Date()
        }
        
        // Save signatures
        // Note: This would need to be implemented based on your Signature model
        
        do {
            try context.save()
        } catch {
            print("Error saving form: \(error)")
        }
    }
}

// MARK: - Supporting Types

enum SignatureType: String {
    case client = "Client"
    case parent = "Parent/Guardian"
    case artist = "Artist"
}

struct SignatureInfo: Identifiable {
    let id = UUID()
    let type: SignatureType
    let image: UIImage
    let date: Date
} 
