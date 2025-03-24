import Foundation

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
