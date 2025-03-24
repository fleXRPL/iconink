import SwiftUI
import PDFKit

struct ConsentFormDetailView: View {
    let form: ConsentForm
    @State private var showingExportOptions = false
    @State private var pdfData: Data?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Client information
                if let client = form.client as? Client {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Client Information")
                            .font(.headline)
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
                    }
                    .padding(.bottom, 8)
                }
                
                // Form content
                Text(form.content)
                    .font(.body)
                
                // Signature
                if let signature = form.signature,
                   let uiImage = UIImage(data: signature) {
                    VStack(alignment: .leading) {
                        Text("Signature")
                            .font(.headline)
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                    }
                    .padding(.vertical, 8)
                }
                
                // Date signed
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date Signed")
                        .font(.headline)
                    Text(form.dateCreated, style: .date)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle(form.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    exportPDF()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingExportOptions) {
            if let pdfData = pdfData {
                ShareSheet(items: [pdfData])
            }
        }
    }
    
    private func exportPDF() {
        // Show loading indicator
        let loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator.startAnimating()
        loadingIndicator.center = UIApplication.shared.windows.first?.center ?? CGPoint(x: 0, y: 0)
        UIApplication.shared.windows.first?.addSubview(loadingIndicator)
        
        // Use background thread for PDF generation
        DispatchQueue.global(qos: .userInitiated).async {
            // Use the enhanced PDFExporter to create a secure PDF with metadata
            let metadata = PDFExporter.standardMetadata(for: self.form)
            
            // Generate the PDF with watermark and optional encryption based on settings
            let generatedPDF: Data?
            if SettingsManager.shared.encryptData {
                generatedPDF = PDFExporter.generateSecurePDF(from: self.form, encrypt: true)
            } else {
                generatedPDF = PDFExporter.generateSecurePDF(from: self.form)
            }
            
            // Add standard metadata
            if let pdf = generatedPDF {
                self.pdfData = PDFExporter.addMetadata(to: pdf, metadata: metadata)
            }
            
            // Update UI on main thread
            DispatchQueue.main.async {
                // Remove loading indicator
                loadingIndicator.removeFromSuperview()
                
                // Add haptic feedback on success
                let generator = UINotificationFeedbackGenerator()
                if self.pdfData != nil {
                    generator.notificationOccurred(.success)
                    self.showingExportOptions = true
                } else {
                    generator.notificationOccurred(.error)
                    // Show error alert (would be implemented in a real app)
                }
            }
        }
    }
}
