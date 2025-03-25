import Foundation

/// Image quality assessment results
enum ImageQuality {
    /// Good quality image suitable for OCR
    case good
    
    /// Acceptable quality image that might produce results
    case acceptable
    
    /// Poor quality image with the reason specified
    case poor(reason: String)
}

/// Errors that can occur during ID scanning
enum IDScannerError: Error {
    /// Failed to convert image for processing
    case imageConversionFailed
    
    /// Image quality is too poor for OCR
    case poorImageQuality(reason: String)
    
    /// Text recognition process failed
    case textRecognitionFailed
    
    /// No text found in the image
    case noTextFound
    
    /// Text found, but not valid ID information
    case invalidTextFound
    
    /// Text found, but confidence too low
    case insufficientTextConfidence
    
    /// General processing error with message
    case processingError(message: String)
}

/// Result of ID scanning operation
enum IDScanResult {
    /// Successful scan with extracted information
    case success(idInfo: [String: String])
    
    /// Failed scan with error
    case failure(error: IDScannerError)
} 