import Foundation
import PDFKit
import UIKit

/// Error types for PDF generation
enum PDFGenerationError: Error {
    case invalidData
    case templateNotFound
    case generationFailed
    case signatureNotFound
    
    var localizedDescription: String {
        switch self {
        case .invalidData:
            return "Invalid data provided for PDF generation"
        case .templateNotFound:
            return "Template not found for the specified form type"
        case .generationFailed:
            return "Failed to generate PDF"
        case .signatureNotFound:
            return "Signature not found"
        }
    }
}

/// Generates PDF documents for consent forms
class PDFGenerator {
    static let shared = PDFGenerator()
    
    private init() {}
    
    /// Generates a consent form PDF
    /// - Parameters:
    ///   - type: The type of consent form
    ///   - fields: Dictionary of form fields
    ///   - signature: Optional signature image
    /// - Returns: Result containing PDF data or error
    func generateConsentForm(
        type: ConsentFormType,
        fields: [String: String],
        signature: UIImage? = nil
    ) -> Result<Data, PDFGenerationError> {
        let pageSize = CGSize(width: 595, height: 842) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            
            let pageRect = context.pdfContextBounds
            
            // Draw header
            drawHeader(in: pageRect, formType: type)
            
            // Draw client information
            drawClientInformation(in: pageRect, fields: fields, yOffset: 100)
            
            // Draw form content
            drawFormContent(in: pageRect, type: type, fields: fields, yOffset: 200)
            
            // Draw signature area
            drawSignatureArea(in: pageRect, signature: signature, yOffset: 600)
            
            // Draw footer
            drawFooter(in: pageRect)
        }
        
        return .success(pdfData)
    }
    
    /// Creates a preview image of the form
    /// - Parameters:
    ///   - type: The type of consent form
    ///   - fields: Dictionary of form fields
    ///   - signature: Optional signature image
    /// - Returns: Preview image
    func createPreview(
        type: ConsentFormType,
        fields: [String: String],
        signature: UIImage? = nil
    ) -> UIImage? {
        let pageSize = CGSize(width: 595, height: 842)
        let renderer = UIGraphicsImageRenderer(size: pageSize)
        
        return renderer.image { context in
            let pageRect = CGRect(origin: .zero, size: pageSize)
            
            // Draw background
            UIColor.white.setFill()
            context.fill(pageRect)
            
            // Draw header
            drawHeader(in: pageRect, formType: type)
            
            // Draw client information
            drawClientInformation(in: pageRect, fields: fields, yOffset: 100)
            
            // Draw form content
            drawFormContent(in: pageRect, type: type, fields: fields, yOffset: 200)
            
            // Draw signature area
            drawSignatureArea(in: pageRect, signature: signature, yOffset: 600)
            
            // Draw footer
            drawFooter(in: pageRect)
        }
    }
    
    // MARK: - Private Drawing Methods
    
    private func drawHeader(in rect: CGRect, formType: ConsentFormType) {
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]
        
        let title = NSAttributedString(string: formType.description, attributes: titleAttributes)
        let titleSize = title.size()
        let titleRect = CGRect(
            x: (rect.width - titleSize.width) / 2,
            y: 30,
            width: titleSize.width,
            height: titleSize.height
        )
        title.draw(in: titleRect)
        
        // Draw date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateString = dateFormatter.string(from: Date())
        
        let dateFont = UIFont.systemFont(ofSize: 14)
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: dateFont,
            .foregroundColor: UIColor.gray
        ]
        
        let date = NSAttributedString(string: "Date: \(dateString)", attributes: dateAttributes)
        let dateRect = CGRect(x: 50, y: 60, width: rect.width - 100, height: 20)
        date.draw(in: dateRect)
    }
    
    private func drawClientInformation(in rect: CGRect, fields: [String: String], yOffset: CGFloat) {
        let sectionFont = UIFont.boldSystemFont(ofSize: 16)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionFont,
            .foregroundColor: UIColor.black
        ]
        
        let sectionTitle = NSAttributedString(string: "Client Information", attributes: sectionAttributes)
        let sectionRect = CGRect(x: 50, y: yOffset, width: rect.width - 100, height: 20)
        sectionTitle.draw(in: sectionRect)
        
        let fieldFont = UIFont.systemFont(ofSize: 12)
        let fieldAttributes: [NSAttributedString.Key: Any] = [
            .font: fieldFont,
            .foregroundColor: UIColor.black
        ]
        
        var currentY = yOffset + 30
        
        // Draw client fields
        let clientFields = ["clientName", "email", "phone", "address"]
        for field in clientFields {
            if let value = fields[field], !value.isEmpty {
                let label = field.replacingOccurrences(of: "client", with: "").capitalized
                let text = "\(label): \(value)"
                let attributedText = NSAttributedString(string: text, attributes: fieldAttributes)
                let textRect = CGRect(x: 50, y: currentY, width: rect.width - 100, height: 15)
                attributedText.draw(in: textRect)
                currentY += 20
            }
        }
    }
    
    private func drawFormContent(in rect: CGRect, type: ConsentFormType, fields: [String: String], yOffset: CGFloat) {
        let sectionFont = UIFont.boldSystemFont(ofSize: 16)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionFont,
            .foregroundColor: UIColor.black
        ]
        
        let sectionTitle = NSAttributedString(string: "Form Details", attributes: sectionAttributes)
        let sectionRect = CGRect(x: 50, y: yOffset, width: rect.width - 100, height: 20)
        sectionTitle.draw(in: sectionRect)
        
        let fieldFont = UIFont.systemFont(ofSize: 12)
        let fieldAttributes: [NSAttributedString.Key: Any] = [
            .font: fieldFont,
            .foregroundColor: UIColor.black
        ]
        
        var currentY = yOffset + 30
        
        // Draw form-specific content based on type
        switch type {
        case .tattoo:
            drawTattooContent(in: rect, fields: fields, yOffset: &currentY, attributes: fieldAttributes)
        case .piercing:
            drawPiercingContent(in: rect, fields: fields, yOffset: &currentY, attributes: fieldAttributes)
        case .minorConsent:
            drawMinorConsentContent(in: rect, fields: fields, yOffset: &currentY, attributes: fieldAttributes)
        case .medicalHistory:
            drawMedicalHistoryContent(in: rect, fields: fields, yOffset: &currentY, attributes: fieldAttributes)
        case .aftercare:
            drawAftercareContent(in: rect, fields: fields, yOffset: &currentY, attributes: fieldAttributes)
        }
    }
    
    private func drawTattooContent(in rect: CGRect, fields: [String: String], yOffset: inout CGFloat, attributes: [NSAttributedString.Key: Any]) {
        let tattooFields = ["designDescription", "bodyLocation", "artistName"]
        for field in tattooFields {
            if let value = fields[field], !value.isEmpty {
                let label = field.replacingOccurrences(of: "design", with: "Design ").capitalized
                let text = "\(label): \(value)"
                let attributedText = NSAttributedString(string: text, attributes: attributes)
                let textRect = CGRect(x: 50, y: yOffset, width: rect.width - 100, height: 15)
                attributedText.draw(in: textRect)
                yOffset += 20
            }
        }
    }
    
    private func drawPiercingContent(in rect: CGRect, fields: [String: String], yOffset: inout CGFloat, attributes: [NSAttributedString.Key: Any]) {
        let piercingFields = ["piercingLocation", "jewelryType", "piercerName"]
        for field in piercingFields {
            if let value = fields[field], !value.isEmpty {
                let label = field.replacingOccurrences(of: "piercing", with: "Piercing ").capitalized
                let text = "\(label): \(value)"
                let attributedText = NSAttributedString(string: text, attributes: attributes)
                let textRect = CGRect(x: 50, y: yOffset, width: rect.width - 100, height: 15)
                attributedText.draw(in: textRect)
                yOffset += 20
            }
        }
    }
    
    private func drawMinorConsentContent(in rect: CGRect, fields: [String: String], yOffset: inout CGFloat, attributes: [NSAttributedString.Key: Any]) {
        let minorFields = ["guardianName", "relationship", "guardianID"]
        for field in minorFields {
            if let value = fields[field], !value.isEmpty {
                let label = field.replacingOccurrences(of: "guardian", with: "Guardian ").capitalized
                let text = "\(label): \(value)"
                let attributedText = NSAttributedString(string: text, attributes: attributes)
                let textRect = CGRect(x: 50, y: yOffset, width: rect.width - 100, height: 15)
                attributedText.draw(in: textRect)
                yOffset += 20
            }
        }
    }
    
    private func drawMedicalHistoryContent(in rect: CGRect, fields: [String: String], yOffset: inout CGFloat, attributes: [NSAttributedString.Key: Any]) {
        let medicalFields = ["allergies", "medications", "medicalConditions"]
        for field in medicalFields {
            if let value = fields[field], !value.isEmpty {
                let label = field.capitalized
                let text = "\(label): \(value)"
                let attributedText = NSAttributedString(string: text, attributes: attributes)
                let textRect = CGRect(x: 50, y: yOffset, width: rect.width - 100, height: 15)
                attributedText.draw(in: textRect)
                yOffset += 20
            }
        }
    }
    
    private func drawAftercareContent(in rect: CGRect, fields: [String: String], yOffset: inout CGFloat, attributes: [NSAttributedString.Key: Any]) {
        let aftercareFields = ["procedureType", "artistName"]
        for field in aftercareFields {
            if let value = fields[field], !value.isEmpty {
                let label = field.replacingOccurrences(of: "procedure", with: "Procedure ").capitalized
                let text = "\(label): \(value)"
                let attributedText = NSAttributedString(string: text, attributes: attributes)
                let textRect = CGRect(x: 50, y: yOffset, width: rect.width - 100, height: 15)
                attributedText.draw(in: textRect)
                yOffset += 20
            }
        }
    }
    
    private func drawSignatureArea(in rect: CGRect, signature: UIImage?, yOffset: CGFloat) {
        let sectionFont = UIFont.boldSystemFont(ofSize: 16)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionFont,
            .foregroundColor: UIColor.black
        ]
        
        let sectionTitle = NSAttributedString(string: "Signature", attributes: sectionAttributes)
        let sectionRect = CGRect(x: 50, y: yOffset, width: rect.width - 100, height: 20)
        sectionTitle.draw(in: sectionRect)
        
        if let signature = signature {
            // Draw signature image
            let signatureRect = CGRect(x: 50, y: yOffset + 30, width: 200, height: 100)
            signature.draw(in: signatureRect)
        } else {
            // Draw signature line
            let lineRect = CGRect(x: 50, y: yOffset + 80, width: 200, height: 1)
            UIColor.black.setFill()
            UIRectFill(lineRect)
        }
        
        // Draw signature label
        let labelFont = UIFont.systemFont(ofSize: 12)
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: UIColor.gray
        ]
        
        let label = NSAttributedString(string: "Client Signature", attributes: labelAttributes)
        let labelRect = CGRect(x: 50, y: yOffset + 140, width: 200, height: 15)
        label.draw(in: labelRect)
    }
    
    private func drawFooter(in rect: CGRect) {
        let footerFont = UIFont.systemFont(ofSize: 10)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footerText = "Generated by IconInk - \(Date())"
        let footer = NSAttributedString(string: footerText, attributes: footerAttributes)
        let footerRect = CGRect(x: 50, y: rect.height - 30, width: rect.width - 100, height: 15)
        footer.draw(in: footerRect)
    }
}