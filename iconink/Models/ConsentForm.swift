import Foundation
import CoreData
import UIKit

// Forward reference
@objc(Client)
class ClientRef: NSManagedObject { }

@objc(ConsentForm)
public class ConsentForm: NSManagedObject, Identifiable {
    @NSManaged public var title: String
    @NSManaged public var content: String
    @NSManaged public var signature: Data?
    @NSManaged public var dateCreated: Date
    @NSManaged public var client: ClientRef?
    
    // Computed property for signature image
    var signatureImage: UIImage? {
        guard let data = signature else { return nil }
        return UIImage(data: data)
    }
    
    // Convenience method to create a PDF from the consent form
    func createPDF() -> Data? {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842)) // A4 size
        
        let data = pdfRenderer.pdfData { context in
            context.beginPage()
            
            // Draw title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24)
            ]
            let titleString = NSAttributedString(string: title, attributes: titleAttributes)
            titleString.draw(at: CGPoint(x: 50, y: 50))
            
            // Draw client name if available
            if let clientName = (client as? Client)?.fullName {
                let clientAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 16)
                ]
                let clientString = NSAttributedString(string: "Client: \(clientName)", attributes: clientAttributes)
                clientString.draw(at: CGPoint(x: 50, y: 90))
            }
            
            // Draw date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14)
            ]
            let dateString = NSAttributedString(string: "Date: \(dateFormatter.string(from: dateCreated))", attributes: dateAttributes)
            dateString.draw(at: CGPoint(x: 50, y: 120))
            
            // Draw content
            let contentAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12)
            ]
            let contentString = NSAttributedString(string: content, attributes: contentAttributes)
            let contentRect = CGRect(x: 50, y: 160, width: 495, height: 500)
            contentString.draw(in: contentRect)
            
            // Draw signature if available
            if let signatureImage = signatureImage {
                let signatureRect = CGRect(x: 50, y: 680, width: 200, height: 100)
                signatureImage.draw(in: signatureRect)
                
                // Draw signature label
                let signatureAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12)
                ]
                let signatureLabel = NSAttributedString(string: "Client Signature", attributes: signatureAttributes)
                signatureLabel.draw(at: CGPoint(x: 50, y: 790))
            }
        }
        
        return data
    }
}

extension ConsentForm {
    /// Creates a fetch request that retrieves ConsentForm instances from the persistence store
    /// - Returns: A configured NSFetchRequest for ConsentForm entities
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ConsentForm> {
        return NSFetchRequest<ConsentForm>(entityName: "ConsentForm")
    }
}
