import Foundation
import UIKit
import PDFKit

/// PDFGenerator provides enhanced PDF generation capabilities for the app
class PDFGenerator {
    
    /// Generates a PDF from a consent form with enhanced formatting and security features
    /// - Parameters:
    ///   - form: The consent form to generate a PDF from
    ///   - includeWatermark: Whether to include a watermark on the PDF
    /// - Returns: PDF data or nil if generation failed
    static func generatePDF(from form: ConsentForm, includeWatermark: Bool = true) -> Data? {
        // Use A4 size for the PDF
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            // Add watermark if requested
            if includeWatermark {
                addWatermark(to: context, in: pageRect)
            }
            
            // Add header with logo and form title
            addHeader(to: context, title: form.title, in: pageRect)
            
            // Add client information
            var yPosition = 120.0
            if let client = form.client as? Client {
                yPosition = addClientInformation(to: context, client: client, yPosition: yPosition)
            }
            
            // Add form content
            yPosition = addFormContent(to: context, content: form.content, yPosition: yPosition)
            
            // Add signature
            if let signature = form.signature {
                yPosition = addSignature(to: context, signatureData: signature, yPosition: yPosition)
            }
            
            // Add footer with date and page number
            addFooter(to: context, date: form.dateCreated, in: pageRect)
        }
    }
    
    // MARK: - Private Helper Methods
    
    private static func addWatermark(to context: UIGraphicsPDFRendererContext, in rect: CGRect) {
        let watermarkText = "IconInk"
        
        // Configure watermark attributes
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 60, weight: .thin),
            .foregroundColor: UIColor.lightGray.withAlphaComponent(0.2)
        ]
        
        // Calculate text size and position for diagonal placement
        let textSize = watermarkText.size(withAttributes: attributes)
        let centerX = rect.width / 2 - textSize.width / 2
        let centerY = rect.height / 2 - textSize.height / 2
        
        // Save graphics state
        context.cgContext.saveGState()
        
        // Rotate context for diagonal watermark
        context.cgContext.translateBy(x: centerX + textSize.width / 2, y: centerY + textSize.height / 2)
        context.cgContext.rotate(by: CGFloat.pi / 4) // 45 degrees
        context.cgContext.translateBy(x: -(centerX + textSize.width / 2), y: -(centerY + textSize.height / 2))
        
        // Draw watermark
        watermarkText.draw(at: CGPoint(x: centerX, y: centerY), withAttributes: attributes)
        
        // Restore graphics state
        context.cgContext.restoreGState()
    }
    
    private static func addHeader(to context: UIGraphicsPDFRendererContext, title: String, in rect: CGRect) {
        // Draw title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]
        
        let titleSize = title.size(withAttributes: titleAttributes)
        let titleX = (rect.width - titleSize.width) / 2 // Center title
        title.draw(at: CGPoint(x: titleX, y: 50), withAttributes: titleAttributes)
        
        // Draw horizontal line under title
        context.cgContext.setStrokeColor(UIColor.gray.cgColor)
        context.cgContext.setLineWidth(1.0)
        context.cgContext.move(to: CGPoint(x: 50, y: 85))
        context.cgContext.addLine(to: CGPoint(x: rect.width - 50, y: 85))
        context.cgContext.strokePath()
    }
    
    private static func addClientInformation(to context: UIGraphicsPDFRendererContext, client: Client, yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition
        
        // Client section title
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        
        "Client Information".draw(at: CGPoint(x: 50, y: currentY), withAttributes: sectionAttributes)
        currentY += 25
        
        // Client details
        let detailAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.darkGray
        ]
        
        // Name
        "Name: \(client.fullName)".draw(at: CGPoint(x: 50, y: currentY), withAttributes: detailAttributes)
        currentY += 20
        
        // Email if available
        if let email = client.email {
            "Email: \(email)".draw(at: CGPoint(x: 50, y: currentY), withAttributes: detailAttributes)
            currentY += 20
        }
        
        // Phone if available
        if let phone = client.phone {
            "Phone: \(phone)".draw(at: CGPoint(x: 50, y: currentY), withAttributes: detailAttributes)
            currentY += 20
        }
        
        // Add some space after client information
        currentY += 15
        
        return currentY
    }
    
    private static func addFormContent(to context: UIGraphicsPDFRendererContext, content: String, yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition
        
        // Content section title
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        
        "Consent Agreement".draw(at: CGPoint(x: 50, y: currentY), withAttributes: sectionAttributes)
        currentY += 25
        
        // Form content
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        
        let contentRect = CGRect(x: 50, y: currentY, width: 495, height: 400)
        let contentString = NSAttributedString(string: content, attributes: contentAttributes)
        let framesetter = CTFramesetterCreateWithAttributedString(contentString)
        
        let path = CGMutablePath()
        path.addRect(contentRect)
        
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, contentString.length), path, nil)
        CTFrameDraw(frame, context.cgContext)
        
        // Calculate the height of the drawn text
        let frameRange = CTFrameGetVisibleStringRange(frame)
        if frameRange.location + frameRange.length < contentString.length {
            // Content didn't fit, would need multiple pages in a real implementation
            // For simplicity, we'll just continue after the visible content
            currentY += 400 // Use the full height we allocated
        } else {
            // Calculate actual height used
            guard let ctLines = CTFrameGetLines(frame) as? [CTLine], !ctLines.isEmpty else {
                return currentY + 20 // Add a small padding if no lines
            }
            
            var lineOrigins = [CGPoint](repeating: .zero, count: ctLines.count)
            CTFrameGetLineOrigins(frame, CFRangeMake(0, ctLines.count), &lineOrigins)
            
            if let lastLineOrigin = lineOrigins.last, let lastLine = ctLines.last {
                var ascent: CGFloat = 0
                var descent: CGFloat = 0
                var leading: CGFloat = 0
                CTLineGetTypographicBounds(lastLine, &ascent, &descent, &leading)
                
                // Calculate the bottom of the last line
                let lastLineBottom = contentRect.origin.y + contentRect.height - lastLineOrigin.y + descent
                currentY = lastLineBottom + 20 // Add some padding
            } else {
                currentY += 20 // Just add minimal spacing if no lines
            }
        }
        
        return currentY
    }
    
    private static func addSignature(to context: UIGraphicsPDFRendererContext, signatureData: Data, yPosition: CGFloat) -> CGFloat {
        var currentY = yPosition
        
        // Signature section title
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        
        "Client Signature".draw(at: CGPoint(x: 50, y: currentY), withAttributes: sectionAttributes)
        currentY += 25
        
        // Draw signature image if available
        if let signatureImage = UIImage(data: signatureData) {
            let signatureRect = CGRect(x: 50, y: currentY, width: 200, height: 100)
            signatureImage.draw(in: signatureRect)
            currentY += 120
        }
        
        return currentY
    }
    
    private static func addFooter(to context: UIGraphicsPDFRendererContext, date: Date, in rect: CGRect) {
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.darkGray
        ]
        
        // Format date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateString = "Date: \(dateFormatter.string(from: date))"
        
        // Draw date at bottom left
        dateString.draw(at: CGPoint(x: 50, y: rect.height - 30), withAttributes: footerAttributes)
        
        // Draw page number at bottom right
        let pageString = "Page 1 of 1"
        let pageStringSize = pageString.size(withAttributes: footerAttributes)
        pageString.draw(at: CGPoint(x: rect.width - 50 - pageStringSize.width, y: rect.height - 30), withAttributes: footerAttributes)
        
        // Draw horizontal line above footer
        context.cgContext.setStrokeColor(UIColor.gray.cgColor)
        context.cgContext.setLineWidth(0.5)
        context.cgContext.move(to: CGPoint(x: 50, y: rect.height - 40))
        context.cgContext.addLine(to: CGPoint(x: rect.width - 50, y: rect.height - 40))
        context.cgContext.strokePath()
    }
}
