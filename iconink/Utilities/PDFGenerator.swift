import Foundation
import UIKit
import PDFKit

/// Error types for PDF generation
enum PDFGenerationError: Error {
    case templateNotFound
    case invalidData
    case generationFailed
    case missingRequiredFields([String])
    
    var localizedDescription: String {
        switch self {
        case .templateNotFound:
            return "Template not found"
        case .invalidData:
            return "Invalid form data"
        case .generationFailed:
            return "Failed to generate PDF"
        case .missingRequiredFields(let fields):
            return "Missing required fields: \(fields.joined(separator: ", "))"
        }
    }
}

/// Service for generating PDF consent forms
class PDFGenerator {
    static let shared = PDFGenerator()
    
    private init() {}
    
    /// Generates a PDF consent form
    /// - Parameters:
    ///   - type: The type of consent form
    ///   - fields: Form field values
    ///   - signature: Optional signature image
    /// - Returns: PDF data or error
    func generateConsentForm(
        type: ConsentFormType,
        fields: [String: String],
        signature: UIImage? = nil
    ) -> Result<Data, PDFGenerationError> {
        // Get template
        let template = ConsentFormTemplateManager.shared.template(for: type)
        
        // Validate required fields
        let missingFields = template.missingFields(fields: fields)
        if !missingFields.isEmpty {
            return .failure(.missingRequiredFields(missingFields))
        }
        
        // Create PDF document
        let pdfMetaData = [
            kCGPDFContextCreator: "IconInk",
            kCGPDFContextAuthor: "IconInk Generated Form",
            kCGPDFContextTitle: type.rawValue
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        do {
            let data = try renderer.pdfData { context in
                context.beginPage()
                
                // Fill template with field values
                var content = template.content
                for (key, value) in fields {
                    content = content.replacingOccurrences(of: "{\(key)}", with: value)
                }
                
                // Draw content
                let textRect = pageRect.insetBy(dx: 50, dy: 50)
                drawText(content, in: textRect)
                
                // Draw signature if provided
                if let signature = signature {
                    let signatureRect = CGRect(x: 50, y: pageRect.height - 150, width: 200, height: 100)
                    signature.draw(in: signatureRect)
                }
            }
            
            return .success(data)
        } catch {
            return .failure(.generationFailed)
        }
    }
    
    /// Draws text in the specified rectangle
    private func drawText(_ text: String, in rect: CGRect) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .paragraphStyle: paragraphStyle
        ]
        
        text.draw(in: rect, withAttributes: attributes)
    }
}

// MARK: - PDF Preview
extension PDFGenerator {
    /// Creates a preview image of the first page
    func createPreview(
        type: ConsentFormType,
        fields: [String: String],
        signature: UIImage? = nil
    ) -> UIImage? {
        switch generateConsentForm(type: type, fields: fields, signature: signature) {
        case .success(let pdfData):
            guard let pdf = PDFDocument(data: pdfData),
                  let page = pdf.page(at: 0) else {
                return nil
            }
            
            let pageRect = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            
            let image = renderer.image { context in
                UIColor.white.set()
                context.fill(pageRect)
                
                context.cgContext.translateBy(x: 0, y: pageRect.height)
                context.cgContext.scaleBy(x: 1.0, y: -1.0)
                
                page.draw(with: .mediaBox, to: context.cgContext)
            }
            
            return image
            
        case .failure:
            return nil
        }
    }
}
