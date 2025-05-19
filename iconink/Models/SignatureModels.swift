import Foundation
import CoreData
import UIKit
import PencilKit

/// Represents the state of a signature
enum SignatureState {
    case empty
    case inProgress
    case completed
    case invalid
}

/// Error types for signature operations
enum SignatureError: Error {
    case invalidData
    case exportFailed
    case validationFailed(String)
    case storageFailed
    
    var localizedDescription: String {
        switch self {
        case .invalidData:
            return "Invalid signature data"
        case .exportFailed:
            return "Failed to export signature"
        case .validationFailed(let reason):
            return "Signature validation failed: \(reason)"
        case .storageFailed:
            return "Failed to store signature"
        }
    }
}

/// Signature validation result
struct SignatureValidationResult {
    let isValid: Bool
    let error: SignatureError?
    
    static let valid = SignatureValidationResult(isValid: true, error: nil)
    static func invalid(_ error: SignatureError) -> SignatureValidationResult {
        SignatureValidationResult(isValid: false, error: error)
    }
}

/// Signature data model
@objc(Signature)
public class Signature: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var signatureData: Data?
    @NSManaged public var createdAt: Date
    @NSManaged public var signedBy: String
    @NSManaged public var isValid: Bool
    @NSManaged public var client: Client?
    @NSManaged public var consentForm: ConsentForm?
    
    /// Creates a new signature instance
    static func create(in context: NSManagedObjectContext,
                      signatureData: Data,
                      signedBy: String,
                      client: Client? = nil,
                      consentForm: ConsentForm? = nil) -> Signature {
        let signature = Signature(context: context)
        signature.id = UUID()
        signature.signatureData = signatureData
        signature.createdAt = Date()
        signature.signedBy = signedBy
        signature.isValid = true
        signature.client = client
        signature.consentForm = consentForm
        return signature
    }
    
    /// Validates the signature
    func validate() -> SignatureValidationResult {
        guard let data = signatureData else {
            return .invalid(.invalidData)
        }
        
        // Check if signature is not empty (has enough data points)
        if data.count < 100 {
            return .invalid(.validationFailed("Signature too small or empty"))
        }
        
        // Additional validation can be added here
        return .valid
    }
    
    /// Exports the signature as a UIImage
    func exportAsImage() -> Result<UIImage, SignatureError> {
        guard let data = signatureData,
              let drawing = try? PKDrawing(data: data) else {
            return .failure(.exportFailed)
        }
        
        let rect = drawing.bounds
        let renderer = UIGraphicsImageRenderer(bounds: rect)
        
        let image = renderer.image { context in
            context.cgContext.setFillColor(UIColor.clear.cgColor)
            context.fill(rect)
            drawing.image(from: rect, scale: UIScreen.main.scale).draw(in: rect)
        }
        
        return .success(image)
    }
}

// MARK: - CoreData Fetch Request
extension Signature {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Signature> {
        return NSFetchRequest<Signature>(entityName: "Signature")
    }
}

// MARK: - Identifiable
extension Signature: Identifiable {} 