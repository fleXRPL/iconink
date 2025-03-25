import Foundation
import Vision
import CoreImage
import SwiftUI

/// Utility for scanning IDs and extracting text information
class IDScanner {
    /// Scan an ID from an image and extract information from it
    /// - Parameters:
    ///   - image: The image containing the ID
    ///   - completion: Completion handler with the scan result
    static func scanID(from image: ImageType, completion: @escaping (IDScanResult) -> Void) {
        // Process with image enhancement pipeline
        let processedImage = processImageForScanning(image)
        performTextRecognition(on: processedImage, completion: completion)
    }
    
    /// Perform text recognition on the provided image
    /// - Parameters:
    ///   - image: The processed image ready for OCR
    ///   - completion: Completion handler with the scan result
    private static func performTextRecognition(on image: ImageType, completion: @escaping (IDScanResult) -> Void) {
        // Check image quality with the quality analyzer
        let imageQuality = IDImageQualityAnalyzer.assessImageQuality(image)
        
        // If image quality is poor, return with error
        if case .poor(let reason) = imageQuality {
            completion(.failure(error: .poorImageQuality(reason: reason)))
            return
        }
        
        // Convert to CGImage for Vision
        #if canImport(UIKit)
        guard let cgImage = image.cgImage else {
            completion(.failure(error: .imageConversionFailed))
            return
        }
        #else
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion(.failure(error: .imageConversionFailed))
            return
        }
        #endif
        
        // Create a Vision request to recognize text
        let request = createTextRecognitionRequest { result in
            completion(result)
        }
        
        // Create a request handler with the image
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Perform the request
        do {
            try requestHandler.perform([request])
        } catch {
            completion(.failure(error: .processingError(message: error.localizedDescription)))
        }
    }
    
    // Methods from IDScannerAdvanced.swift - declared here, implemented in extension
    
    /// Process an image through the enhancement pipeline for optimal OCR
    /// - Parameter image: The original image to process
    /// - Returns: An enhanced image ready for OCR
    static func processImageForScanning(_ image: ImageType) -> ImageType {
        // Implementation in IDScannerAdvanced.swift
        IDImageEnhancer.enhanceForOCR(image).success?.image ?? image
    }
    
    /// Create a Vision text recognition request
    /// - Parameter completion: Completion handler with the scan result
    /// - Returns: A configured VNRecognizeTextRequest
    static func createTextRecognitionRequest(completion: @escaping (IDScanResult) -> Void) -> VNRecognizeTextRequest {
        // Implementation in IDScannerAdvanced.swift
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US", "en-GB"]
        return request
    }
    
    /// Create a fallback scan function that tries adaptive thresholding for low-contrast images
    /// - Parameters:
    ///   - image: The image containing the ID
    ///   - completion: Completion handler with the scan result
    static func scanLowContrastID(from image: ImageType, completion: @escaping (IDScanResult) -> Void) {
        // Implementation in IDScannerAdvanced.swift
        scanID(from: image, completion: completion)
    }
} 