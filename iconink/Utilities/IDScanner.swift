import Foundation
import Vision
import UIKit

/// IDScanner provides functionality for scanning and extracting information from ID documents
class IDScanner {
    
    /// Completion handler for ID scanning
    typealias ScanCompletionHandler = (IDScanResult) -> Void
    
    /// Scans an ID image and extracts text information
    /// - Parameters:
    ///   - image: The image containing the ID to scan
    ///   - completion: Callback with the scan result
    static func scanID(from image: UIImage, completion: @escaping ScanCompletionHandler) {
        // Convert UIImage to CIImage
        guard let ciImage = CIImage(image: image) else {
            completion(.failure(error: "Failed to convert image"))
            return
        }
        
        // Create a request handler
        let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        // Create a text recognition request
        let request = VNRecognizeTextRequest { request, error in
            // Handle errors
            if let error = error {
                completion(.failure(error: error.localizedDescription))
                return
            }
            
            // Process the results
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(error: "No text found"))
                return
            }
            
            // Extract text from observations
            let recognizedText = observations.compactMap { observation -> String? in
                // Get the top candidate
                return observation.topCandidates(1).first?.string
            }
            
            // Parse the extracted text to find ID information
            let extractedInfo = parseIDInformation(from: recognizedText)
            completion(.success(info: extractedInfo))
        }
        
        // Configure the request
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // Perform the request
        do {
            try requestHandler.perform([request])
        } catch {
            completion(.failure(error: error.localizedDescription))
        }
    }
    
    /// Parses extracted text to find ID information
    /// - Parameter textLines: Array of text lines from the ID
    /// - Returns: Dictionary of extracted information
    private static func parseIDInformation(from textLines: [String]) -> [String: String] {
        var extractedInfo: [String: String] = [:]
        
        // Common patterns to look for in IDs
        let namePattern = "(?:NAME|NAME:)\\s*([A-Z\\s]+)"
        let dobPattern = "(?:DOB|DATE OF BIRTH|BIRTH DATE|BIRTH)\\s*([0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4})"
        let expiryPattern = "(?:EXP|EXPIRY|EXPIRES)\\s*([0-9]{1,2}[/-][0-9]{1,2}[/-][0-9]{2,4})"
        let idNumberPattern = "(?:ID|ID NO|LICENSE|LICENSE NO|DL|DL NO)[.:#]?\\s*([A-Z0-9\\s-]+)"
        let addressPattern = "(?:ADDRESS|ADDR)\\s*([A-Z0-9\\s,.-]+)"
        
        // Join all text lines for easier pattern matching
        let fullText = textLines.joined(separator: " ")
        
        // Extract name
        if let nameMatch = fullText.range(of: namePattern, options: .regularExpression) {
            let name = String(fullText[nameMatch]).replacingOccurrences(of: "NAME:|NAME", with: "", options: .regularExpression)
            extractedInfo["name"] = name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Extract date of birth
        if let dobMatch = fullText.range(of: dobPattern, options: .regularExpression) {
            let dob = String(fullText[dobMatch]).replacingOccurrences(of: "DOB:|DOB|DATE OF BIRTH:|DATE OF BIRTH|BIRTH DATE:|BIRTH DATE|BIRTH:", with: "", options: .regularExpression)
            extractedInfo["dob"] = dob.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Extract expiry date
        if let expiryMatch = fullText.range(of: expiryPattern, options: .regularExpression) {
            let expiry = String(fullText[expiryMatch]).replacingOccurrences(of: "EXP:|EXP|EXPIRY:|EXPIRY|EXPIRES:", with: "", options: .regularExpression)
            extractedInfo["expiry"] = expiry.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Extract ID number
        if let idMatch = fullText.range(of: idNumberPattern, options: .regularExpression) {
            let idNumber = String(fullText[idMatch]).replacingOccurrences(of: "ID:|ID|ID NO:|ID NO|LICENSE:|LICENSE|LICENSE NO:|LICENSE NO|DL:|DL|DL NO:|DL NO", with: "", options: .regularExpression)
            extractedInfo["idNumber"] = idNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Extract address
        if let addressMatch = fullText.range(of: addressPattern, options: .regularExpression) {
            let address = String(fullText[addressMatch]).replacingOccurrences(of: "ADDRESS:|ADDRESS|ADDR:|ADDR", with: "", options: .regularExpression)
            extractedInfo["address"] = address.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Process individual lines for more specific information
        for line in textLines {
            // Look for email addresses
            if line.contains("@") && line.contains(".") {
                extractedInfo["email"] = line.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Look for phone numbers (simple pattern)
            let phonePattern = "\\(?[0-9]{3}\\)?[-. ]?[0-9]{3}[-. ]?[0-9]{4}"
            if let phoneMatch = line.range(of: phonePattern, options: .regularExpression) {
                extractedInfo["phone"] = String(line[phoneMatch]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return extractedInfo
    }
}

/// Represents the result of an ID scan
enum IDScanResult {
    case success(info: [String: String])
    case failure(error: String)
    
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
    
    /// Returns the error message if failed, nil otherwise
    var errorMessage: String? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}