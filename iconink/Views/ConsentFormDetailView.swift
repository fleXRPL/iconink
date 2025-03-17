import SwiftUI
import CoreData
import PDFKit

struct ConsentFormDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var viewModel: ConsentFormDetailViewModel
    @State private var showingSignatureCapture = false
    @State private var showingPDFPreview = false
    @State private var showingDeleteAlert = false
    @State private var showingEditForm = false
    
    init(consentForm: ConsentForm) {
        self.viewModel = ConsentFormDetailViewModel(consentForm: consentForm)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Information
                headerSection
                
                Divider()
                
                // Client Information
                clientSection
                
                Divider()
                
                // Service Details
                serviceSection
                
                Divider()
                
                // Risk Acknowledgments
                risksSection
                
                Divider()
                
                // Signatures
                signaturesSection
                
                // Action Buttons
                actionButtons
            }
            .padding()
        }
        .navigationTitle("Consent Form Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Form", systemImage: "trash")
                    }
                    
                    Button {
                        showingEditForm = true
                    } label: {
                        Label("Edit Form", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingSignatureCapture) {
            SignatureView(consentForm: viewModel.consentForm) { _ in
                viewModel.refreshSignatures()
            }
        }
        .sheet(isPresented: $showingPDFPreview) {
            if let pdfData = viewModel.generatePDF() {
                PDFPreviewView(pdfData: pdfData)
            }
        }
        .alert("Delete Consent Form", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteConsentForm(context: viewContext)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this consent form? This action cannot be undone.")
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.consentForm.formTitle ?? "Untitled Form")
                .font(.title2)
                .bold()
            
            Text("Status: \(viewModel.formStatusString)")
                .foregroundColor(viewModel.formStatusColor)
            
            Text("Created: \(viewModel.formattedCreationDate)")
                .foregroundColor(.secondary)
        }
    }
    
    private var clientSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Client Information")
                .font(.headline)
            
            if let client = viewModel.consentForm.client {
                Text(client.fullName)
                    .font(.subheadline)
                
                if let email = client.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let phone = client.phone {
                    Text(phone)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No client associated")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var serviceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Service Details")
                .font(.headline)
            
            Text("Date: \(viewModel.formattedServiceDate)")
            
            Text("Description:")
                .font(.subheadline)
            Text(viewModel.consentForm.serviceDescription ?? "No description provided")
                .padding(.leading)
            
            if let aftercare = viewModel.consentForm.aftercareInstructions,
               !aftercare.isEmpty {
                Text("Aftercare Instructions:")
                    .font(.subheadline)
                Text(aftercare)
                    .padding(.leading)
            }
        }
    }
    
    private var risksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Acknowledged Risks")
                .font(.headline)
            
            ForEach(viewModel.acknowledgedRisks, id: \.self) { risk in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(risk)
                }
                .padding(.leading)
            }
            
            if let additional = viewModel.consentForm.additionalAcknowledgments,
               !additional.isEmpty {
                Text("Additional Acknowledgments:")
                    .font(.subheadline)
                Text(additional)
                    .padding(.leading)
            }
        }
    }
    
    private var signaturesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Signatures")
                .font(.headline)
            
            ForEach(viewModel.signatures) { signature in
                SignatureRowView(signature: signature)
            }
            
            if viewModel.canAddMoreSignatures {
                Button {
                    showingSignatureCapture = true
                } label: {
                    Label("Add Signature", systemImage: "signature")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 15) {
            Button {
                showingPDFPreview = true
            } label: {
                Label("Generate PDF", systemImage: "doc.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding(.top)
    }
}

// MARK: - Supporting Views

struct SignatureRowView: View {
    let signature: Signature
    
    var body: some View {
        HStack {
            if let image = signature.loadSignature() {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
            }
            
            VStack(alignment: .leading) {
                Text(signature.signatureTypeString)
                    .font(.subheadline)
                Text(signature.captureDate?.formatted(date: .abbreviated, time: .shortened) ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct PDFPreviewView: View {
    let pdfData: Data
    
    var body: some View {
        NavigationStack {
            PDFKitView(data: pdfData)
                .navigationTitle("PDF Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ShareLink(item: pdfData, preview: SharePreview("Consent Form", image: Image(systemName: "doc.fill")))
                    }
                }
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: data)
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(data: data)
    }
}

// MARK: - ViewModel

class ConsentFormDetailViewModel: ObservableObject {
    let consentForm: ConsentForm
    @Published var signatures: [Signature] = []
    @Published var acknowledgedRisks: [String] = []
    @Published var isGeneratingPDF = false
    @Published var errorMessage: String?
    
    init(consentForm: ConsentForm) {
        self.consentForm = consentForm
        self.loadData()
    }
    
    private func loadData() {
        refreshSignatures()
        loadAcknowledgedRisks()
    }
    
    func refreshSignatures() {
        guard let signatureSet = consentForm.signatures as? Set<Signature> else { return }
        self.signatures = Array(signatureSet).sorted { 
            ($0.captureDate ?? Date.distantPast) < ($1.captureDate ?? Date.distantPast)
        }
    }
    
    private func loadAcknowledgedRisks() {
        guard let risksJSON = consentForm.acknowledgedRisksJSON,
              !risksJSON.isEmpty else {
            self.acknowledgedRisks = []
            return
        }
        
        do {
            guard let data = risksJSON.data(using: .utf8) else { return }
            self.acknowledgedRisks = try JSONDecoder().decode([String].self, from: data)
        } catch {
            print("Error decoding risks: \(error)")
            self.acknowledgedRisks = []
        }
    }
    
    var formStatusString: String {
        switch consentForm.formStatus {
        case 0: return "Draft"
        case 1: return "Pending Signatures"
        case 2: return "Completed"
        default: return "Unknown"
        }
    }
    
    var formStatusColor: Color {
        switch consentForm.formStatus {
        case 0: return .orange
        case 1: return .blue
        case 2: return .green
        default: return .gray
        }
    }
    
    var formattedCreationDate: String {
        consentForm.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown"
    }
    
    var formattedServiceDate: String {
        consentForm.serviceDate?.formatted(date: .long) ?? "Not scheduled"
    }
    
    var canAddMoreSignatures: Bool {
        return consentForm.formStatus != 2 && signatures.count < 4 // Maximum 4 signatures allowed
    }
    
    func deleteConsentForm(context: NSManagedObjectContext) {
        // Delete associated files first
        if let formPath = consentForm.formPath {
            _ = FileManager.deleteFile(at: formPath)
        }
        
        // Delete the form
        context.delete(consentForm)
        
        do {
            try context.save()
        } catch {
            print("Error deleting consent form: \(error)")
            errorMessage = "Failed to delete consent form"
        }
    }
    
    func generatePDF() -> Data? {
        isGeneratingPDF = true
        defer { isGeneratingPDF = false }
        
        // Generate PDF using PDFGenerator
        let pdfData = PDFGenerator.generateConsentFormPDF(from: consentForm)
        
        // Save the PDF if generated successfully
        if let data = pdfData,
           let fileName = savePDFToDocuments(data) {
            // Update the form's PDF path
            consentForm.formPath = fileName
            
            do {
                try PersistenceController.shared.container.viewContext.save()
            } catch {
                print("Error saving form path: \(error)")
            }
        }
        
        return pdfData
    }
    
    private func savePDFToDocuments(_ data: Data) -> String? {
        let fileName = "consent_form_\(UUID().uuidString).pdf"
        let fileURL = FileManager.documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileName
        } catch {
            print("Error saving PDF: \(error)")
            return nil
        }
    }
}

#Preview {
    NavigationStack {
        ConsentFormDetailView(consentForm: ConsentForm())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 
