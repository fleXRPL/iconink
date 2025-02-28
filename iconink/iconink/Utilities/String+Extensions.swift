//
//  String+Extensions.swift
//  iconink
//
//  Created by Garot Conklin on 2/27/25.
//

import Foundation

extension String {
    
    // MARK: - Validation
    
    /// Returns true if the string is a valid email address
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    /// Returns true if the string is a valid US phone number
    var isValidUSPhoneNumber: Bool {
        let phoneRegex = "^\\d{10}$|^\\(\\d{3}\\)\\s*\\d{3}-\\d{4}$|^\\d{3}-\\d{3}-\\d{4}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: self)
    }
    
    /// Returns true if the string is a valid ZIP code
    var isValidZIPCode: Bool {
        let zipRegex = "^\\d{5}(-\\d{4})?$"
        let zipPredicate = NSPredicate(format: "SELF MATCHES %@", zipRegex)
        return zipPredicate.evaluate(with: self)
    }
    
    /// Returns true if the string contains only letters
    var isAlphabetic: Bool {
        return !isEmpty && range(of: "[^a-zA-Z]", options: .regularExpression) == nil
    }
    
    /// Returns true if the string contains only numbers
    var isNumeric: Bool {
        return !isEmpty && range(of: "[^0-9]", options: .regularExpression) == nil
    }
    
    /// Returns true if the string contains only letters and numbers
    var isAlphanumeric: Bool {
        return !isEmpty && range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }
    
    // MARK: - Formatting
    
    /// Returns a formatted phone number (e.g., (123) 456-7890)
    var formattedPhoneNumber: String {
        // Remove all non-numeric characters
        let digits = components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Format the phone number
        if digits.count == 10 {
            let areaCode = digits.prefix(3)
            let middle = digits.dropFirst(3).prefix(3)
            let end = digits.dropFirst(6)
            return "(\(areaCode)) \(middle)-\(end)"
        }
        
        return self // Return original if not a 10-digit number
    }
    
    /// Returns a formatted ZIP code (e.g., 12345 or 12345-6789)
    var formattedZIPCode: String {
        // Remove all non-numeric characters
        let digits = components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Format the ZIP code
        if digits.count == 9 {
            let first = digits.prefix(5)
            let last = digits.dropFirst(5)
            return "\(first)-\(last)"
        } else if digits.count == 5 {
            return digits
        }
        
        return self // Return original if not a 5 or 9-digit number
    }
    
    /// Returns a capitalized version of the string with the first letter of each word capitalized
    var titleCased: String {
        return self.components(separatedBy: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
    
    /// Returns a truncated version of the string with an ellipsis if it exceeds the specified length
    func truncated(toLength length: Int, withTrailing trailing: String = "...") -> String {
        if self.count <= length {
            return self
        }
        
        return String(self.prefix(length)) + trailing
    }
    
    /// Returns a string with the specified prefix removed
    func removingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
    
    /// Returns a string with the specified suffix removed
    func removingSuffix(_ suffix: String) -> String {
        guard self.hasSuffix(suffix) else { return self }
        return String(self.dropLast(suffix.count))
    }
    
    /// Returns a string with leading and trailing whitespace and newlines removed
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Returns a string with all whitespace and newlines removed
    var withoutWhitespace: String {
        return self.components(separatedBy: .whitespacesAndNewlines).joined()
    }
    
    /// Returns a string with all occurrences of the specified characters removed
    func removing(charactersIn set: CharacterSet) -> String {
        return self.components(separatedBy: set).joined()
    }
    
    /// Returns a string with all non-alphanumeric characters removed
    var alphanumericOnly: String {
        return self.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
    }
    
    /// Returns a string with all non-numeric characters removed
    var numericOnly: String {
        return self.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }
    
    /// Returns a string with all non-alphabetic characters removed
    var alphabeticOnly: String {
        return self.components(separatedBy: CharacterSet.letters.inverted).joined()
    }
} 
