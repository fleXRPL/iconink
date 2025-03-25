import Foundation
import Vision
import CoreImage
import SwiftUI

/// Extension to IDScanner providing advanced scanning capabilities
extension IDScanner {
    
    /// Process an image through the enhancement pipeline for optimal OCR
    /// - Parameter image: The original image to process
    /// - Returns: An enhanced image ready for OCR
    static func processImageForScanning(_ image: ImageType) -> ImageType {
        // First try to deskew the image if it's tilted
        let deskewResult = IDImageEnhancer.deskewImage(image)
        switch deskewResult {
        case .success(let deskewedImage):
            // Then apply OCR-specific enhancements
            let enhancementResult = IDImageEnhancer.enhanceForOCR(deskewedImage)
            switch enhancementResult {
            case .success(let enhanced):
                return enhanced
            case .failure:
                // Fallback to original if enhancement fails
                return deskewedImage
            }
        case .failure:
            // Fallback to original image if deskew fails
            return image
        }
    }
    
    /// Create a Vision text recognition request
    /// - Parameter completion: Completion handler with the scan result
    /// - Returns: A configured VNRecognizeTextRequest
    static func createTextRecognitionRequest(completion: @escaping (IDScanResult) -> Void) -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest { request, error in
            // Handle errors
            if let error = error {
                completion(.failure(error: .textRecognitionFailed))
                return
            }
            
            // Get the text observation results
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(error: .textRecognitionFailed))
                return
            }
            
            // If no text found, return error
            if observations.isEmpty {
                completion(.failure(error: .noTextFound))
                return
            }
            
            // Extract text from observations
            var extractedText: [String] = []
            let confidenceThreshold: Float = 0.3
            
            for observation in observations {
                // Get the top candidate with confidence above threshold
                if let recognizedText = observation.topCandidates(1).first,
                   recognizedText.confidence > confidenceThreshold {
                    extractedText.append(recognizedText.string)
                }
            }
            
            // Check if extracted text is empty
            if extractedText.isEmpty {
                completion(.failure(error: .insufficientTextConfidence))
                return
            }
            
            // Parse the extracted text using the IDTextParser
            let parsedInfo = IDTextParser.parseIDInformation(from: extractedText)
            
            // Validate the extracted information
            if !IDTextParser.validateExtractedInfo(parsedInfo) {
                completion(.failure(error: .invalidTextFound))
                return
            }
            
            // Return the successfully parsed ID information
            completion(.success(idInfo: parsedInfo))
        }
        
        // Configure the text recognition request
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // For IDs, we can specify common ID-related languages
        request.recognitionLanguages = ["en-US", "en-GB", "es-US", "fr-FR", "de-DE"]
        
        return request
    }
    
    /// Create a fallback scan function that tries adaptive thresholding for low-contrast images
    /// - Parameters:
    ///   - image: The image containing the ID
    ///   - completion: Completion handler with the scan result
    static func scanLowContrastID(from image: ImageType, completion: @escaping (IDScanResult) -> Void) {
        // Apply adaptive thresholding for better text contrast
        let thresholdResult = IDImageEnhancer.adaptiveThreshold(image: image, thresholdConstant: 2.0)
        
        switch thresholdResult {
        case .success(let thresholdedImage):
            // Use the enhanced image for scanning
            scanID(from: thresholdedImage, completion: completion)
        case .failure:
            // Fall back to original method if thresholding fails
            scanID(from: image, completion: completion)
        }
    }
} 