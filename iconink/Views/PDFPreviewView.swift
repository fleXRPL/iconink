import SwiftUI
import PDFKit
import UIKit

/// PDFPreviewView provides a view for displaying and sharing PDF documents
struct PDFPreviewView: View {
    let pdfData: Data
    let fileName: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var showingSaveSuccess = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // PDF Preview using PDFKit
                PDFKitRepresentedView(pdfData: pdfData)
                    .edgesIgnoringSafeArea([.horizontal, .bottom])
                
                // Action buttons
                HStack(spacing: 20) {
                    Button(action: sharePDF) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: savePDF) {
                        Label("Save", systemImage: "arrow.down.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding()
            }
            .navigationTitle("PDF Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = saveToTemporaryDirectory() {
                    ShareSheet(items: [url])
                }
            }
            .alert("PDF Saved", isPresented: $showingSaveSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The PDF has been saved to your documents folder.")
            }
        }
    }
    
    /// Shares the PDF using the system share sheet
    private func sharePDF() {
        showingShareSheet = true
    }
    
    /// Saves the PDF to the documents directory
    private func savePDF() {
        if let url = PDFExporter.savePDF(pdfData, fileName: fileName) {
            print("PDF saved to: \(url.path)")
            showingSaveSuccess = true
        }
    }
    
    /// Saves the PDF to a temporary directory for sharing
    private func saveToTemporaryDirectory() -> URL? {
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let fileURL = tempDirectoryURL.appendingPathComponent("\(fileName).pdf")
        
        do {
            try pdfData.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving PDF to temporary directory: \(error)")
            return nil
        }
    }
}

/// UIViewRepresentable wrapper for PDFView
struct PDFKitRepresentedView: UIViewRepresentable {
    let pdfData: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemBackground
        
        if let document = PDFDocument(data: pdfData) {
            pdfView.document = document
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // No updates needed
    }
}

/// UIViewControllerRepresentable for UIActivityViewController (Share Sheet)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}
