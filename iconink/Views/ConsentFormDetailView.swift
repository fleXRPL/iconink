import SwiftUI
import CoreData

struct ConsentFormDetailView: View {
    let form: ConsentForm
    @State private var showingExportOptions = false
    @State private var pdfData: Data?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Client information
                if let client = form.client {
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
                    Text("Date Created")
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
        // Generate PDF using the form's createPDF method
        if let pdfData = form.createPDF() {
            self.pdfData = pdfData
            showingExportOptions = true
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
