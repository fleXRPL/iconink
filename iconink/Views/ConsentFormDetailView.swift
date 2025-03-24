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
        // Use the enhanced PDFExporter to create a secure PDF with metadata
        let metadata = PDFExporter.standardMetadata(for: form)
        
        // Generate the PDF with watermark
        if let generatedPDF = PDFExporter.generateSecurePDF(from: form) {
            // Add standard metadata
            pdfData = PDFExporter.addMetadata(to: generatedPDF, metadata: metadata)
            showingExportOptions = true
        }
    }
}
