import Foundation
import Vision
import CoreImage
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

// Import models and utilities
import CoreData
import SwiftUI

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
}

/// IDScanner provides functionality for scanning and extracting information from ID documents
class IDScanner {
    
    /// Completion handler for ID scanning
    typealias ScanCompletionHandler = (IDScanResult) -> Void
    
    /// Scans an ID image and extracts text information
    /// - Parameters:
    ///   - image: The image containing the ID to scan
    ///   - completion: Callback with the scan result
    #if canImport(UIKit)
    static func scanID(from image: UIImage, completion: @escaping ScanCompletionHandler) {
    #else
    static func scanID(from image: NSImage, completion: @escaping ScanCompletionHandler) {
    #endif
        // Convert UIImage to CIImage
        #if canImport(UIKit)
        guard let ciImage = CIImage(image: image) else {
        #else
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let ciImage = CIImage(cgImage: cgImage) else {
        #endif
            completion(.failure(error: "Failed to convert image", errorType: .imageConversion))
            return
        }
        
        // Check image quality
        let imageQuality = IDImageQualityAnalyzer.assessImageQuality(image)
        if imageQuality == .poor {
            completion(.failure(error: "Image quality is too low. Please take a clearer photo with good lighting.", errorType: .poorQuality))
            return
        }
        
        // Create a request handler
        let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        // Create a text recognition request
        let request = VNRecognizeTextRequest { request, error in
            // Handle errors
            if let error = error {
                let errorMessage: String
                if let vnError = error as? VNError {
                    switch vnError.code {
                    case .outOfBoundsError:
                        errorMessage = "The ID is outside the camera frame. Please center it properly."
                    case .invalidImage:
                        errorMessage = "The image is invalid. Please try again with a clearer photo."
                    case .operationFailed:
                        errorMessage = "The scanning operation failed. Please try again."
                    case .invalidOption:
                        errorMessage = "Invalid scanning options. Please try again."
                    case .invalidFormat:
                        errorMessage = "The image format is not supported. Please try again with a different image."
                    case .internalError:
                        errorMessage = "An internal error occurred. Please try again later."
                    case .unsupportedRevision:
                        errorMessage = "This operation is not supported on your device."
                    case .requestCancelled:
                        errorMessage = "The scanning was cancelled."
                    case .invalidParameter:
                        errorMessage = "Invalid scanning parameters. Please try again."
                    case .notImplemented:
                        errorMessage = "This feature is not implemented on your device."
                    case .unsupportedOperation:
                        errorMessage = "This operation is not supported on your device."
                    case .invalidArgument:
                        errorMessage = "Invalid scanning arguments. Please try again."
                    case .dataUnavailable:
                        errorMessage = "The required data is unavailable. Please try again."
                    default:
                        errorMessage = "Unknown error: \(error.localizedDescription)"
                    }
                } else {
                    errorMessage = "Unknown error: \(error.localizedDescription)"
                }
                
                completion(.failure(error: errorMessage, errorType: .recognitionFailed))
                return
            }
            
            // No recognized text
            guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                completion(.failure(error: "No text found in the image. Please ensure the ID is visible and well-lit.", errorType: .noTextFound))
                return
            }
            
            // Extract text from observations with confidence
            var extractedText: [String] = []
            
            for observation in observations {
                if let recognizedText = observation.topCandidates(1).first {
                    if recognizedText.confidence > 0.3 {
                        extractedText.append(recognizedText.string)
                    }
                }
            }
            
            if extractedText.isEmpty {
                let errorMessage = "Could not recognize text with sufficient confidence. " 
                    + "Please try again with better lighting and focus."
                completion(.failure(error: errorMessage, errorType: .lowConfidence))
                return
            }
            
            // Parse the extracted text into structured data using IDTextParser
            let parsedInfo = IDTextParser.parseIDInformation(from: extractedText)
            
            // Validate the extracted information
            if !IDTextParser.validateExtractedInfo(parsedInfo) {
                completion(.failure(error: "Could not extract required information from ID. Please ensure entire ID is visible and text is clear.", 
                                    errorType: .missingRequiredFields))
                return
            }
            
            completion(.success(info: parsedInfo))
        }
        
        // Configure the request
        request.recognitionLevel = VNRequestTextRecognitionLevel.accurate
        request.usesLanguageCorrection = true
        // Set recognition languages (English as primary)
        request.recognitionLanguages = ["en-US", "en-GB"]
        
        // Perform the request
        do {
            try requestHandler.perform([request])
        } catch {
            let errorMessage: String
            if let vnError = error as? VNError {
                switch vnError.code {
                case .outOfBoundsError:
                    errorMessage = "The ID is outside the camera frame. Please center it properly."
                case .invalidImage:
                    errorMessage = "The image is invalid. Please try again with a clearer photo."
                case .operationFailed:
                    errorMessage = "The scanning operation failed. Please try again."
                default:
                    errorMessage = "An error occurred during scanning: \(vnError.localizedDescription)"
                }
            } else {
                errorMessage = "Unknown error: \(error.localizedDescription)"
            }
            
            completion(.failure(error: errorMessage, errorType: .requestFailed))
        }
    }
    
    /// Assesses the quality of an image to determine if it's suitable for text recognition
    /// - Parameter image: The image to assess
    /// - Returns: The quality assessment result
    #if canImport(UIKit)
    private static func assessImageQuality(_ image: UIImage) -> ImageQuality {
    #else
    private static func assessImageQuality(_ image: NSImage) -> ImageQuality {
    #endif
        // Get image dimensions
        #if canImport(UIKit)
        let width = image.size.width * image.scale
        let height = image.size.height * image.scale
        #else
        let width = image.size.width
        let height = image.size.height
        #endif
        
        // Check resolution
        let minDimension = min(width, height)
        if minDimension < 800 {
            print("Image quality check: Low resolution - \(width) x \(height)")
            return .poor
        }
        
        // Detect blur
        if let blurScore = detectBlur(image: image), blurScore > 0.7 {
            print("Image quality check: High blur score - \(blurScore)")
            return .poor
        }
        
        // Convert to grayscale for analysis
        #if canImport(UIKit)
        guard let ciImage = CIImage(image: image) else {
        #else
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let ciImage = CIImage(cgImage: cgImage) else {
        #endif
            print("Image quality check: Failed to convert to CIImage")
            return .poor
        }
        
        // Check brightness
        if let brightness = getAverageBrightness(ciImage: ciImage) {
            // Too dark or too bright
            if brightness < 0.2 || brightness > 0.9 {
                print("Image quality check: Poor lighting - brightness \(brightness)")
                return .poor
            }
            
            // Acceptable but not ideal
            if brightness < 0.25 || brightness > 0.85 {
                return .acceptable
            }
        }
        
        // If all checks pass, the image is good
        return .good
    }
    
    /// Calculates the average brightness of an image
    /// - Parameter ciImage: The CIImage to analyze
    /// - Returns: Average brightness value between 0 and 1, or nil if calculation fails
    private static func getAverageBrightness(ciImage: CIImage) -> Float? {
        // Create a very small thumbnail to get average color
        let context = CIContext(options: nil)
        let scale = max(1, min(ciImage.extent.width, ciImage.extent.height) / 100)
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: 1/scale, y: 1/scale))
        
        // Convert to grayscale
        guard let grayscale = CIFilter(name: "CIPhotoEffectMono", parameters: [kCIInputImageKey: scaledImage])?.outputImage,
              let cgImage = context.createCGImage(grayscale, from: grayscale.extent) else {
            return nil
        }
        
        // Get bitmap data
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = width * 4
        let bitmapSize = bytesPerRow * height
        
        guard let data = calloc(bitmapSize, MemoryLayout<UInt8>.size) else {
            return nil
        }
        defer { free(data) }
        
        // Create bitmap context
        guard let context = CGContext(data: data,
                                     width: width,
                                     height: height,
                                     bitsPerComponent: 8,
                                     bytesPerRow: bytesPerRow,
                                     space: CGColorSpaceCreateDeviceRGB(),
                                     bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        
        // Draw image in context
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(cgImage, in: rect)
        
        // Calculate average brightness
        var totalBrightness: Float = 0
        let buffer = data.assumingMemoryBound(to: UInt8.self)
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                // Average RGB components
                let brightness = (Float(buffer[offset]) + Float(buffer[offset + 1]) + Float(buffer[offset + 2])) / (3.0 * 255.0)
                totalBrightness += brightness
            }
        }
        
        return totalBrightness / Float(width * height)
    }
    
    /// Detects the amount of blur in an image
    /// - Parameter image: The image to analyze
    /// - Returns: Blur score between 0 and 1 (higher means more blurry), or nil if detection fails
    #if canImport(UIKit)
    private static func detectBlur(image: UIImage) -> Float? {
    #else
    private static func detectBlur(image: NSImage) -> Float? {
    #endif
        #if canImport(UIKit)
        guard let cgImage = image.cgImage else { return nil }
        #else
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        #endif
        
        // Convert to grayscale
        let context = CIContext(options: nil)
        let ciImage = CIImage(cgImage: cgImage)
        guard let grayscale = CIFilter(name: "CIPhotoEffectMono", parameters: [kCIInputImageKey: ciImage])?.outputImage,
              let grayCGImage = context.createCGImage(grayscale, from: grayscale.extent) else {
            return nil
        }
        
        // Create an edge detection filter (Laplacian)
        let inputImage = CIImage(cgImage: grayCGImage)
        let edgeFilter = CIFilter(name: "CIEdges")
        edgeFilter?.setValue(inputImage, forKey: kCIInputImageKey)
        edgeFilter?.setValue(5.0, forKey: "inputIntensity") // Increase this value for more sensitivity
        
        guard let edgeOutput = edgeFilter?.outputImage,
              let edgeCGImage = context.createCGImage(edgeOutput, from: edgeOutput.extent) else {
            return nil
        }
        
        // Calculate standard deviation of edge image
        var total: Float = 0
        var squaredTotal: Float = 0
        var count: Int = 0
        
        // Create a bitmap for the edge image
        let width = edgeCGImage.width
        let height = edgeCGImage.height
        let bytesPerRow = width * 4
        let bitmapSize = bytesPerRow * height
        
        guard let data = calloc(bitmapSize, MemoryLayout<UInt8>.size) else {
            return nil
        }
        defer { free(data) }
        
        // Create bitmap context
        guard let bitmapContext = CGContext(data: data,
                                          width: width,
                                          height: height,
                                          bitsPerComponent: 8,
                                          bytesPerRow: bytesPerRow,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        
        // Draw edge image in context
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        bitmapContext.draw(edgeCGImage, in: rect)
        
        // Calculate standard deviation
        let buffer = data.assumingMemoryBound(to: UInt8.self)
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                let value = Float(buffer[offset]) // Use the red channel
                total += value
                squaredTotal += value * value
                count += 1
            }
        }
        
        if count == 0 {
            return nil
        }
        
        let mean = total / Float(count)
        let variance = (squaredTotal / Float(count)) - (mean * mean)
        let standardDeviation = sqrt(variance)
        
        // Normalize standard deviation to a 0-1 score where 0 is not blurry and 1 is very blurry
        // Inverse relationship: higher standard deviation means less blur
        let maxSD: Float = 50.0 // Adjust this based on empirical testing
        let blurScore = max(0, min(1, 1.0 - (standardDeviation / maxSD)))
        
        return blurScore
    }
    
    /// Parses text extracted from an ID into structured information
    /// - Parameter textLines: Array of text lines extracted from the ID
    /// - Returns: Dictionary with structured ID information
    private static func parseIDInformation(from textLines: [String]) -> [String: String] {
        var info: [String: String] = [:]
        
        // Common patterns to look for in IDs - shorter pattern names
        let nameRgx = try? NSRegularExpression(
            pattern: "(?i)^(name|full name|first name|last name|given name|surname|forename)\\s*:?\\s*(.+)$"
        )
        let dobRgx = try? NSRegularExpression(
            pattern: "(?i)(?:^|\\s)(dob|date of birth|birth date|born|birthday)\\s*:?\\s*(\\d{1,2}[/.-]\\d{1,2}[/.-]\\d{2,4})(?:$|\\s)"
        )
        let idRgx = try? NSRegularExpression(
            pattern: "(?i)(?:^|\\s)(id(?:\\s+|:|\\.|-)(?:number|no|#)?|license(?:\\s+|:|\\.|-)(?:number|no|#)?)\\s*:?\\s*([a-z0-9-]{4,})(?:$|\\s)"
        )
        let expRgx = try? NSRegularExpression(
            pattern: "(?i)(?:^|\\s)(exp|expiration|expires|expiry|expiration date|valid until)\\s*:?\\s*(\\d{1,2}[/.-]\\d{1,2}[/.-]\\d{2,4})(?:$|\\s)"
        )
        let addrRgx = try? NSRegularExpression(
            pattern: "(?i)(?:^|\\s)(address|addr|residence|location)\\s*:?\\s*(.+)$"
        )
        
        // Process each line of text
        for line in textLines {
            // Clean up the text
            var sanitizedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            sanitizedLine = sanitizedLine
                .replacingOccurrences(of: "'", with: "'")
                .replacingOccurrences(of: "\"", with: "\"")
                .replacingOccurrences(of: ";", with: ",")
            
            // Look for common ID fields
            // Name
            if let match = nameRgx?.firstMatch(in: sanitizedLine, options: [], 
                                              range: NSRange(sanitizedLine.startIndex..., in: sanitizedLine)) {
                if let valueRange = Range(match.range(at: 2), in: sanitizedLine) {
                    let name = String(sanitizedLine[valueRange])
                    let value = sanitizeFreeValue(name)
                    if !value.isEmpty && (info["name"] == nil || value.count > info["name"]!.count) {
                        info["name"] = value
                    }
                }
            }
            
            // Birthdate
            if let match = dobRgx?.firstMatch(in: sanitizedLine, options: [], 
                                             range: NSRange(sanitizedLine.startIndex..., in: sanitizedLine)) {
                if let valueRange = Range(match.range(at: 2), in: sanitizedLine) {
                    let date = String(sanitizedLine[valueRange])
                    let value = sanitizeDateValue(date)
                    if !value.isEmpty {
                        info["dob"] = value
                    }
                }
            }
            
            // ID number
            if let match = idRgx?.firstMatch(in: sanitizedLine, options: [], 
                                            range: NSRange(sanitizedLine.startIndex..., in: sanitizedLine)) {
                if let valueRange = Range(match.range(at: 2), in: sanitizedLine) {
                    let idText = String(sanitizedLine[valueRange])
                    let value = sanitizeIDValue(idText)
                    if !value.isEmpty {
                        info["idNumber"] = value
                    }
                }
            }
            
            // Expiration date
            if let match = expRgx?.firstMatch(in: sanitizedLine, options: [], 
                                             range: NSRange(sanitizedLine.startIndex..., in: sanitizedLine)) {
                if let valueRange = Range(match.range(at: 2), in: sanitizedLine) {
                    let date = String(sanitizedLine[valueRange])
                    let value = sanitizeDateValue(date)
                    if !value.isEmpty {
                        info["expirationDate"] = value
                    }
                }
            }
            
            // Address
            if let match = addrRgx?.firstMatch(in: sanitizedLine, options: [], 
                                              range: NSRange(sanitizedLine.startIndex..., in: sanitizedLine)) {
                if let valueRange = Range(match.range(at: 2), in: sanitizedLine) {
                    let addressText = String(sanitizedLine[valueRange])
                    let value = sanitizeFreeValue(addressText)
                    if !value.isEmpty && (info["address"] == nil || value.count > info["address"]!.count) {
                        info["address"] = value
                    }
                }
            }
        }
        
        return info
    }
    
    /// Validates that the extracted information contains required fields
    /// - Parameter info: Dictionary with extracted information
    /// - Returns: True if required fields are present
    private static func validateExtractedInfo(_ info: [String: String]) -> Bool {
        // Minimum required fields for a valid ID scan
        // We need at least a name and one identifying number (ID or license number)
        let hasName = info["name"] != nil && !info["name"]!.isEmpty
        let hasIDNumber = info["idNumber"] != nil && !info["idNumber"]!.isEmpty
        
        return hasName && hasIDNumber
    }
    
    /// Sanitizes name and address values
    /// - Parameter value: Raw text value
    /// - Returns: Sanitized value
    private static func sanitizeFreeValue(_ value: String) -> String {
        var sanitizedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Clean up common OCR issues
        sanitizedValue = sanitizedValue
            .replacingOccurrences(of: "'", with: "'")
            .replacingOccurrences(of: "\"", with: "\"")
            .replacingOccurrences(of: ";", with: ",")
            
        // Handle names specially
        if sanitizedValue.isEmpty || sanitizedValue.count < 2 {
            return ""
        }
        
        // If fully uppercase, convert to title case
        if sanitizedValue == sanitizedValue.uppercased() && sanitizedValue.count > 3 {
            sanitizedValue = sanitizedValue.lowercased().split(separator: " ")
                .map { String($0.prefix(1).uppercased() + $0.dropFirst()) }
                .joined(separator: " ")
        }
        
        return sanitizedValue
    }
    
    /// Sanitizes date values
    /// - Parameter value: Raw date value
    /// - Returns: Normalized date value
    private static func sanitizeDateValue(_ value: String) -> String {
        let sanitizedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate date format
        if sanitizedValue.isEmpty {
            return ""
        }
        
        // Check for common date patterns (MM/DD/YYYY, DD-MM-YYYY, etc.)
        return sanitizedValue
    }
    
    /// Sanitizes ID values
    /// - Parameter value: Raw ID value
    /// - Returns: Sanitized ID value
    private static func sanitizeIDValue(_ value: String) -> String {
        var sanitizedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Clean up common OCR issues
        sanitizedValue = sanitizedValue
            .replacingOccurrences(of: "O", with: "0")
            .replacingOccurrences(of: "I", with: "1")
            .replacingOccurrences(of: " ", with: "")
            
        // If too short, probably an error
        if sanitizedValue.count < 4 {
            return ""
        }
        
        return sanitizedValue
    }
}
