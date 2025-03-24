import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct NewConsentFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let client: Client
    
    @State private var title = ""
    @State private var content = ""
    @State private var showingSignature = false
    @State private var signatureData: Data?
    @State private var showingExportOptions = false
    @State private var pdfData: Data?
    @AppStorage("defaultConsent") private var defaultConsent = "Standard"
    
    // Template content based on form type
    private var templateContent: String {
        switch defaultConsent {
        case "Tattoo":
            return "I, the undersigned, consent to receive a tattoo from the artist at this establishment. " +
                   "I acknowledge that I have been informed of the risks associated with getting a tattoo, " +
                   "including but not limited to infection, allergic reactions, and scarring. " +
                   "I confirm that I am not under the influence of alcohol or drugs. " +
                   "I understand that the tattoo is permanent and that removal may be difficult, expensive, and may leave scarring."
        case "Piercing":
            return "I, the undersigned, consent to receive a body piercing from the professional at this establishment. " +
                   "I acknowledge that I have been informed of the risks associated with getting a piercing, " +
                   "including but not limited to infection, allergic reactions, and scarring. " +
                   "I confirm that I am not under the influence of alcohol or drugs. " +
                   "I understand proper aftercare is essential and has been explained to me."
        case "Microblading":
            return "I, the undersigned, consent to receive microblading services from the technician at this establishment. " +
                   "I acknowledge that I have been informed of the risks associated with microblading, " +
                   "including but not limited to infection, allergic reactions, and undesired results. " +
                   "I understand that the results may fade over time and touch-ups may be necessary. " +
                   "I confirm that I am not pregnant or breastfeeding."
        default: // Standard
            return "I, the undersigned, hereby consent to the procedure described herein and " +
                   "acknowledge that I have been fully informed of the risks and benefits associated with this procedure. " +
                   "I confirm that I am of legal age and sound mind to provide this consent."
        }
    }
    
    var body: some View {
        Form {
            Section("Form Details") {
                TextField("Title", text: $title)
                    .onAppear {
                        if title.isEmpty {
                            title = "\(defaultConsent) Consent Form"
                        }
                    }
                TextEditor(text: $content)
                    .frame(height: 200)
                    .onAppear {
                        if content.isEmpty {
                            content = templateContent
                        }
                    }
            }
            
            Section {
                Button {
                    showingSignature = true
                } label: {
                    HStack {
                        Text(signatureData == nil ? "Add Signature" : "Change Signature")
                        Spacer()
                        if let data = signatureData,
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 44)
                        }
                    }
                }
            }
        }
        .navigationTitle("New Consent Form")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveForm()
                }
                .disabled(title.isEmpty || content.isEmpty || signatureData == nil)
            }
        }
        .sheet(isPresented: $showingSignature) {
            SignatureCaptureView(signatureData: $signatureData)
        }
        .sheet(isPresented: $showingExportOptions) {
            if let pdfData = pdfData {
                ShareSheet(items: [pdfData])
            }
        }
    }
    
    private func saveForm() {
        let form = ConsentForm(context: viewContext)
        form.title = title
        form.content = content
        form.signature = signatureData
        form.dateCreated = Date()
        form.client = client
        
        do {
            try viewContext.save()
            
            // Generate PDF for export using the enhanced PDFExporter with security features
            let metadata = PDFExporter.standardMetadata(for: form)
            
            // Generate the PDF with watermark
            if let generatedPDF = PDFExporter.generateSecurePDF(from: form) {
                // Add standard metadata
                pdfData = PDFExporter.addMetadata(to: generatedPDF, metadata: metadata)
                showingExportOptions = true
            }
            
            // Dismiss after a short delay to allow the export sheet to appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        } catch {
            print("Failed to save consent form: \(error.localizedDescription)")
        }
    }
}

// ShareSheet for exporting PDF
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
                .disabled(title.isEmpty || content.isEmpty || signatureData == nil)
            }
        }
        .sheet(isPresented: $showingSignature) {
            SignatureCaptureView(signatureData: $signatureData)
        }
    }
    
    private func saveForm() {
        let form = ConsentForm(context: viewContext)
        form.title = title
        form.content = content
        form.signature = signatureData
        form.dateCreated = Date()
        form.client = client
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving form: \(error)")
        }
    }
}
