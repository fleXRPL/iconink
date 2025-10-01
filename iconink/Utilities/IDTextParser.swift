import Foundation

/// Parses and validates ID information extracted from scanned documents
class IDTextParser {
    
    /// Parses ID information from recognized text strings
    /// - Parameter recognizedStrings: Array of recognized text strings
    /// - Returns: Dictionary of extracted information
    static func parseIDInformation(from recognizedStrings: [String]) -> [String: String] {
        var extractedInfo: [String: String] = [:]
        
        let fullText = recognizedStrings.joined(separator: " ").uppercased()
        
        // Extract name (usually appears first or after "NAME")
        if let name = extractName(from: recognizedStrings) {
            extractedInfo["name"] = name
        }
        
        // Extract date of birth
        if let dob = extractDateOfBirth(from: fullText) {
            extractedInfo["dateOfBirth"] = dob
        }
        
        // Extract ID number
        if let idNumber = extractIDNumber(from: fullText) {
            extractedInfo["idNumber"] = idNumber
        }
        
        // Extract expiration date
        if let expirationDate = extractExpirationDate(from: fullText) {
            extractedInfo["expirationDate"] = expirationDate
        }
        
        // Extract address
        if let address = extractAddress(from: recognizedStrings) {
            extractedInfo["address"] = address
        }
        
        // Extract state
        if let state = extractState(from: fullText) {
            extractedInfo["state"] = state
        }
        
        return extractedInfo
    }
    
    /// Validates extracted information to ensure required fields are present
    /// - Parameter info: Dictionary of extracted information
    /// - Returns: True if validation passes, false otherwise
    static func validateExtractedInfo(_ info: [String: String]) -> Bool {
        // Check for required fields
        let requiredFields = ["name", "idNumber"]
        
        for field in requiredFields {
            guard let value = info[field], !value.isEmpty else {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Private Extraction Methods
    
    private static func extractName(from strings: [String]) -> String? {
        // Look for patterns like "NAME: John Doe" or "John Doe"
        for string in strings {
            let cleanString = string.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip very short strings or strings that look like dates/numbers
            if cleanString.count < 3 || cleanString.contains(where: { $0.isNumber }) {
                continue
            }
            
            // Check if it contains "NAME:" prefix
            if cleanString.uppercased().contains("NAME:") {
                let components = cleanString.components(separatedBy: ":")
                if components.count > 1 {
                    return components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            // Check if it looks like a name (contains letters and spaces, no numbers)
            if cleanString.contains(" ") && !cleanString.contains(where: { $0.isNumber }) {
                let words = cleanString.components(separatedBy: " ")
                if words.count >= 2 && words.allSatisfy({ $0.allSatisfy({ $0.isLetter }) }) {
                    return cleanString
                }
            }
        }
        
        return nil
    }
    
    private static func extractDateOfBirth(from text: String) -> String? {
        // Look for date patterns like MM/DD/YYYY or MM-DD-YYYY
        let datePattern = #"(\d{1,2}[/-]\d{1,2}[/-]\d{4})"#
        let regex = try? NSRegularExpression(pattern: datePattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let match = regex?.firstMatch(in: text, options: [], range: range) {
            let dateString = (text as NSString).substring(with: match.range)
            return dateString
        }
        
        return nil
    }
    
    private static func extractIDNumber(from text: String) -> String? {
        // Look for ID number patterns (alphanumeric, usually 8-12 characters)
        let idPattern = #"([A-Z0-9]{8,12})"#
        let regex = try? NSRegularExpression(pattern: idPattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let match = regex?.firstMatch(in: text, options: [], range: range) {
            let idString = (text as NSString).substring(with: match.range)
            return idString
        }
        
        return nil
    }
    
    private static func extractExpirationDate(from text: String) -> String? {
        // Look for expiration date patterns
        let expirationPattern = #"(EXP|EXPIRES?)[:\s]*(\d{1,2}[/-]\d{1,2}[/-]\d{4})"#
        let regex = try? NSRegularExpression(pattern: expirationPattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let match = regex?.firstMatch(in: text, options: [], range: range) {
            let dateString = (text as NSString).substring(with: match.range(at: 2))
            return dateString
        }
        
        return nil
    }
    
    private static func extractAddress(from strings: [String]) -> String? {
        // Look for address patterns (numbers followed by street names)
        for string in strings {
            let cleanString = string.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if it looks like an address (starts with number, contains street keywords)
            let streetKeywords = ["ST", "STREET", "AVE", "AVENUE", "RD", "ROAD", "BLVD", "BOULEVARD", "DR", "DRIVE", "LN", "LANE", "CT", "COURT"]
            
            if cleanString.first?.isNumber == true && streetKeywords.contains(where: { cleanString.uppercased().contains($0) }) {
                return cleanString
            }
        }
        
        return nil
    }
    
    private static func extractState(from text: String) -> String? {
        // Look for state abbreviations or full state names
        let statePattern = #"\b([A-Z]{2})\b"#
        let regex = try? NSRegularExpression(pattern: statePattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let match = regex?.firstMatch(in: text, options: [], range: range) {
            let stateString = (text as NSString).substring(with: match.range)
            return stateString
        }
        
        return nil
    }
}
