import Foundation

/// Provides parsing and extraction of text data from ID scans
class IDTextParser {
    
    /// Parses text extracted from an ID into structured information
    /// - Parameter textLines: Array of text lines extracted from the ID
    /// - Returns: Dictionary with structured ID information
    static func parseIDInformation(from textLines: [String]) -> [String: String] {
        var info: [String: String] = [:]
        
        // Process each line of text
        for line in textLines {
            let sanitizedLine = sanitizeTextLine(line)
            
            // Process each field type one by one
            processNameField(from: sanitizedLine, info: &info)
            processBirthDateField(from: sanitizedLine, info: &info)
            processIDNumberField(from: sanitizedLine, info: &info)
            processExpirationDateField(from: sanitizedLine, info: &info)
            processAddressField(from: sanitizedLine, info: &info)
        }
        
        return info
    }
    
    /// Cleans and prepares a text line for processing
    /// - Parameter line: Raw text line
    /// - Returns: Sanitized text line
    private static func sanitizeTextLine(_ line: String) -> String {
        let sanitizedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        return sanitizedLine
            .replacingOccurrences(of: "'", with: "'")
            .replacingOccurrences(of: "\"", with: "\"")
            .replacingOccurrences(of: ";", with: ",")
    }
    
    /// Process text line for name information
    /// - Parameters:
    ///   - text: Sanitized text line
    ///   - info: Reference to the info dictionary
    private static func processNameField(from text: String, info: inout [String: String]) {
        let pattern = "(?i)^(name|full name|first name|last name|given name|surname|forename)\\s*:?\\s*(.+)$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        
        if let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
           let valueRange = Range(match.range(at: 2), in: text) {
            let name = String(text[valueRange])
            let value = sanitizeFreeValue(name)
            if !value.isEmpty {
                // Only replace if new value is longer or current doesn't exist
                if let existingName = info["name"] {
                    if value.count > existingName.count {
                        info["name"] = value
                    }
                } else {
                    info["name"] = value
                }
            }
        }
    }
    
    /// Process text line for birth date information
    /// - Parameters:
    ///   - text: Sanitized text line
    ///   - info: Reference to the info dictionary
    private static func processBirthDateField(from text: String, info: inout [String: String]) {
        let pattern = "(?i)(?:^|\\s)(dob|date of birth|birth date|born|birthday)\\s*:?\\s*(\\d{1,2}[/.-]\\d{1,2}[/.-]\\d{2,4})(?:$|\\s)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        
        if let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
           let valueRange = Range(match.range(at: 2), in: text) {
            let date = String(text[valueRange])
            let value = sanitizeDateValue(date)
            if !value.isEmpty {
                info["dob"] = value
            }
        }
    }
    
    /// Process text line for ID number information
    /// - Parameters:
    ///   - text: Sanitized text line
    ///   - info: Reference to the info dictionary
    private static func processIDNumberField(from text: String, info: inout [String: String]) {
        let pattern = "(?i)(?:^|\\s)(id(?:\\s+|:|\\.|-)(?:number|no|#)?|license(?:\\s+|:|\\.|-)(?:number|no|#)?)\\s*:?\\s*([a-z0-9-]{4,})(?:$|\\s)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        
        if let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
           let valueRange = Range(match.range(at: 2), in: text) {
            let idText = String(text[valueRange])
            let value = sanitizeIDValue(idText)
            if !value.isEmpty {
                info["idNumber"] = value
            }
        }
    }
    
    /// Process text line for expiration date information
    /// - Parameters:
    ///   - text: Sanitized text line
    ///   - info: Reference to the info dictionary
    private static func processExpirationDateField(from text: String, info: inout [String: String]) {
        let pattern = "(?i)(?:^|\\s)(exp|expiration|expires|expiry|expiration date|valid until)" + 
                      "\\s*:?\\s*(\\d{1,2}[/.-]\\d{1,2}[/.-]\\d{2,4})(?:$|\\s)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        
        if let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
           let valueRange = Range(match.range(at: 2), in: text) {
            let date = String(text[valueRange])
            let value = sanitizeDateValue(date)
            if !value.isEmpty {
                info["expirationDate"] = value
            }
        }
    }
    
    /// Process text line for address information
    /// - Parameters:
    ///   - text: Sanitized text line
    ///   - info: Reference to the info dictionary
    private static func processAddressField(from text: String, info: inout [String: String]) {
        let pattern = "(?i)(?:^|\\s)(address|addr|residence|location)\\s*:?\\s*(.+)$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        
        if let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
           let valueRange = Range(match.range(at: 2), in: text) {
            let addressText = String(text[valueRange])
            let value = sanitizeFreeValue(addressText)
            if !value.isEmpty {
                // Only replace if new value is longer or current doesn't exist
                if let existingAddress = info["address"] {
                    if value.count > existingAddress.count {
                        info["address"] = value
                    }
                } else {
                    info["address"] = value
                }
            }
        }
    }
    
    /// Validates that the extracted information contains required fields
    /// - Parameter info: Dictionary with extracted information
    /// - Returns: True if required fields are present
    static func validateExtractedInfo(_ info: [String: String]) -> Bool {
        // Minimum required fields for a valid ID scan
        // We need at least a name and one identifying number (ID or license number)
        guard let name = info["name"], !name.isEmpty else { return false }
        guard let idNumber = info["idNumber"], !idNumber.isEmpty else { return false }
        
        return true
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
