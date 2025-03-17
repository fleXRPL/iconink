import Foundation
import PDFKit
import UIKit

class PDFGenerator {
    static func generateConsentFormPDF(from form: ConsentForm) -> Data? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        return renderer.pdfData { context in
            context.beginPage()
            drawHeader(in: context, form: form)
            drawClientInformation(in: context, form: form)
            drawServiceDetails(in: context, form: form)
            drawRiskAcknowledgments(in: context, form: form)
            drawSignatures(in: context, form: form)
            drawFooter(in: context, form: form)
        }
    }
    
    private static func drawHeader(in context: UIGraphicsPDFRendererContext, form: ConsentForm) {
        // Header implementation
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24)
        ]
        form.formTitle?.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
    }
    
    private static func drawClientInformation(in context: UIGraphicsPDFRendererContext, form: ConsentForm) {
        // Client information implementation
        let clientAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12)
        ]
        if let client = form.client {
            client.fullName.draw(at: CGPoint(x: 50, y: 100), withAttributes: clientAttributes)
            // Add other client details
        }
    }
    
    private static func drawServiceDetails(in context: UIGraphicsPDFRendererContext, form: ConsentForm) {
        // Service details implementation
        let detailAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12)
        ]
        form.serviceDescription?.draw(at: CGPoint(x: 50, y: 200), withAttributes: detailAttributes)
        form.aftercareInstructions?.draw(at: CGPoint(x: 50, y: 300), withAttributes: detailAttributes)
    }
    
    private static func drawRiskAcknowledgments(in context: UIGraphicsPDFRendererContext, form: ConsentForm) {
        // Risk acknowledgments implementation
        let riskAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12)
        ]
        if let risks = form.acknowledgedRisksJSON {
            risks.draw(at: CGPoint(x: 50, y: 400), withAttributes: riskAttributes)
        }
    }
    
    private static func drawSignatures(in context: UIGraphicsPDFRendererContext, form: ConsentForm) {
        // Signatures implementation
        if let signatures = form.signatures as? Set<Signature> {
            // Draw signatures
        }
    }
    
    private static func drawFooter(in context: UIGraphicsPDFRendererContext, form: ConsentForm) {
        // Footer implementation
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10)
        ]
        let footer = "Generated on \(Date().formatted())"
        footer.draw(at: CGPoint(x: 50, y: 700), withAttributes: footerAttributes)
    }
}

// MARK: - Helper Extensions

extension ConsentForm {
    var formTypeString: String {
        switch formType {
        case 0: return "Tattoo"
        case 1: return "Piercing"
        case 2: return "Other"
        default: return "Unknown"
        }
    }
} 
