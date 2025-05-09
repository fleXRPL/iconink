import Foundation
import CoreData

/// Error types for ID scanning
enum IDScanErrorType {
    case imageConversion
    case poorQuality
    case noTextFound
    case recognitionFailed
    case invalidIDFormat
    case requestFailed
    case lowConfidence
    case missingRequiredFields
}

/// Image quality assessment results
enum ImageQuality {
    case good
    case acceptable
    case poor
}

/// Result of ID scanning operation
enum IDScanResult {
    /// Successful scan with extracted information
    case success(info: [String: String])
    
    /// Failed scan with error message and type
    case failure(error: String, errorType: IDScanErrorType)
    
    /// Returns whether the scan was successful
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    /// Returns the extracted information if successful, empty dictionary otherwise
    var extractedInfo: [String: String] {
        switch self {
        case .success(let info):
            return info
        case .failure:
            return [:]
        }
    }
    
    /// Returns the error message if failure, nil otherwise
    var errorMessage: String? {
        switch self {
        case .success:
            return nil
        case .failure(let error, _):
            return error
        }
    }
    
    /// Returns the error type if failure, nil otherwise
    var errorType: IDScanErrorType? {
        switch self {
        case .success:
            return nil
        case .failure(_, let errorType):
            return errorType
        }
    }
}

/// Represents a scanned ID document
@objc(IDScan)
public class IDScan: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var scanDate: Date
    @NSManaged public var imageData: Data?
    @NSManaged public var extractedInfo: [String: String]
    @NSManaged public var client: Client?
    @NSManaged public var isValid: Bool
    @NSManaged public var validationErrors: [String]?
    @NSManaged public var scanQuality: Double
    @NSManaged public var scanType: String
}

extension IDScan {
    /// Creates a new ID scan with the given information
    /// - Parameters:
    ///   - context: The managed object context
    ///   - imageData: The scanned image data
    ///   - extractedInfo: The extracted information from the scan
    ///   - client: Optional associated client
    /// - Returns: A new IDScan instance
    static func create(in context: NSManagedObjectContext,
                      imageData: Data?,
                      extractedInfo: [String: String],
                      client: Client? = nil) -> IDScan {
        let scan = IDScan(context: context)
        scan.id = UUID()
        scan.scanDate = Date()
        scan.imageData = imageData
        scan.extractedInfo = extractedInfo
        scan.client = client
        scan.isValid = IDTextParser.validateExtractedInfo(extractedInfo)
        scan.scanQuality = 1.0
        scan.scanType = "ID"
        return scan
    }
    
    /// Validates the scan and updates validation status
    func validate() {
        isValid = IDTextParser.validateExtractedInfo(extractedInfo)
        if !isValid {
            validationErrors = ["Missing required fields"]
        }
    }
    
    /// Updates the scan quality score
    /// - Parameter quality: The quality score (0.0 to 1.0)
    func updateQuality(_ quality: Double) {
        scanQuality = max(0.0, min(1.0, quality))
    }
}

// MARK: - CoreData Model Extension
extension IDScan {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<IDScan> {
        return NSFetchRequest<IDScan>(entityName: "IDScan")
    }
}

// MARK: - Identifiable
extension IDScan: Identifiable {} 
