import Foundation
import UIKit
import PDFKit

/// PDFExporter provides enhanced PDF generation and security features for consent forms
class PDFExporter {
    
    /// Generates a secure PDF from a consent form with optional encryption
    /// - Parameters:
    ///   - form: The consent form to generate a PDF from
    ///   - encrypt: Whether to encrypt the PDF data
    /// - Returns: PDF data or nil if generation failed
    static func generateSecurePDF(from form: ConsentForm, encrypt: Bool = false) -> Data? {
        // First generate the PDF using the PDFGenerator
        guard let pdfData = PDFGenerator.generatePDF(from: form, includeWatermark: true) else {
            return nil
        }
        
        // If encryption is requested, encrypt the PDF data
        if encrypt {
            return SecurityManager.shared.encryptData(pdfData)
        }
        
        return pdfData
    }
    
    /// Adds metadata to a PDF document
    /// - Parameters:
    ///   - pdfData: The PDF data to add metadata to
    ///   - metadata: Dictionary of metadata key-value pairs
    /// - Returns: PDF data with metadata or original data if adding metadata failed
    static func addMetadata(to pdfData: Data, metadata: [String: String]) -> Data {
        // Create a PDF document from the data
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            return pdfData
        }
        
        // Add metadata to the document
        for (key, value) in metadata {
            pdfDocument.documentAttributes?[key] = value
        }
        
        // Convert back to data
        if let updatedData = pdfDocument.dataRepresentation() {
            return updatedData
        }
        
        return pdfData
    }
    
    /// Saves a PDF to the app's documents directory
    /// - Parameters:
    ///   - pdfData: The PDF data to save
    ///   - fileName: The name to use for the file (without extension)
    /// - Returns: URL to the saved file or nil if saving failed
    static func savePDF(_ pdfData: Data, fileName: String) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Failed to access documents directory")
            return nil
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(fileName).appendingPathExtension("pdf")
        
        do {
            try pdfData.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving PDF: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Generates standard metadata for a consent form PDF
    /// - Parameter form: The consent form to generate metadata for
    /// - Returns: Dictionary of metadata key-value pairs
    static func standardMetadata(for form: ConsentForm) -> [String: String] {
        var metadata: [String: String] = [
            PDFDocumentAttribute.titleAttribute: form.title,
            PDFDocumentAttribute.creatorAttribute: "IconInk",
            PDFDocumentAttribute.creationDateAttribute: ISO8601DateFormatter().string(from: form.dateCreated),
            PDFDocumentAttribute.modificationDateAttribute: ISO8601DateFormatter().string(from: Date())
        ]
        
        // Add client information if available
        if let client = form.client as? Client {
            metadata[PDFDocumentAttribute.authorAttribute] = client.fullName
            if let email = client.email {
                metadata["ClientEmail"] = email
            }
        }
        
        return metadata
    }
}
