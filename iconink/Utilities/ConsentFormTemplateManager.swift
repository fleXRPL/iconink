import Foundation

/// Manages consent form templates and validation
class ConsentFormTemplateManager {
    static let shared = ConsentFormTemplateManager()
    
    private init() {}
    
    /// Gets the template for a specific form type
    /// - Parameter type: The consent form type
    /// - Returns: The template for the form type
    func template(for type: ConsentFormType) -> ConsentFormTemplate {
        switch type {
        case .tattoo:
            return TattooConsentTemplate()
        case .piercing:
            return PiercingConsentTemplate()
        case .minorConsent:
            return MinorConsentTemplate()
        case .medicalHistory:
            return MedicalHistoryTemplate()
        case .aftercare:
            return AftercareTemplate()
        }
    }
}

/// Base protocol for consent form templates
protocol ConsentFormTemplate {
    var requiredFields: [String] { get }
    var optionalFields: [String] { get }
    
    func validate(fields: [String: String]) -> Bool
    func getContent(for fields: [String: String]) -> String
}

/// Tattoo consent form template
struct TattooConsentTemplate: ConsentFormTemplate {
    let requiredFields = ["clientName", "designDescription", "bodyLocation", "artistName"]
    let optionalFields = ["email", "phone", "address"]
    
    func validate(fields: [String: String]) -> Bool {
        return requiredFields.allSatisfy { field in
            guard let value = fields[field] else { return false }
            return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    func getContent(for fields: [String: String]) -> String {
        return """
        TATTOO CONSENT FORM
        
        I, \(fields["clientName"] ?? ""), hereby consent to receive a tattoo at the location of \(fields["bodyLocation"] ?? "").
        
        Design Description: \(fields["designDescription"] ?? "")
        Artist: \(fields["artistName"] ?? "")
        
        I understand the risks associated with tattooing and agree to follow all aftercare instructions.
        
        Client Signature: _________________________
        Date: _________________________
        """
    }
}

/// Piercing consent form template
struct PiercingConsentTemplate: ConsentFormTemplate {
    let requiredFields = ["clientName", "piercingLocation", "jewelryType", "piercerName"]
    let optionalFields = ["email", "phone", "address"]
    
    func validate(fields: [String: String]) -> Bool {
        return requiredFields.allSatisfy { field in
            guard let value = fields[field] else { return false }
            return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    func getContent(for fields: [String: String]) -> String {
        return """
        PIERCING CONSENT FORM
        
        I, \(fields["clientName"] ?? ""), hereby consent to receive a piercing at the location of \(fields["piercingLocation"] ?? "").
        
        Jewelry Type: \(fields["jewelryType"] ?? "")
        Piercer: \(fields["piercerName"] ?? "")
        
        I understand the risks associated with piercing and agree to follow all aftercare instructions.
        
        Client Signature: _________________________
        Date: _________________________
        """
    }
}

/// Minor consent form template
struct MinorConsentTemplate: ConsentFormTemplate {
    let requiredFields = ["clientName", "guardianName", "relationship", "guardianID"]
    let optionalFields = ["email", "phone", "address"]
    
    func validate(fields: [String: String]) -> Bool {
        return requiredFields.allSatisfy { field in
            guard let value = fields[field] else { return false }
            return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    func getContent(for fields: [String: String]) -> String {
        return """
        MINOR CONSENT FORM
        
        I, \(fields["guardianName"] ?? ""), am the \(fields["relationship"] ?? "") of \(fields["clientName"] ?? "").
        
        Guardian ID: \(fields["guardianID"] ?? "")
        
        I hereby give consent for the above-named minor to receive the requested service.
        
        Guardian Signature: _________________________
        Date: _________________________
        """
    }
}

/// Medical history template
struct MedicalHistoryTemplate: ConsentFormTemplate {
    let requiredFields = ["clientName"]
    let optionalFields = ["allergies", "medications", "medicalConditions", "email", "phone", "address"]
    
    func validate(fields: [String: String]) -> Bool {
        return requiredFields.allSatisfy { field in
            guard let value = fields[field] else { return false }
            return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    func getContent(for fields: [String: String]) -> String {
        return """
        MEDICAL HISTORY FORM
        
        Client Name: \(fields["clientName"] ?? "")
        
        Allergies: \(fields["allergies"] ?? "None reported")
        Medications: \(fields["medications"] ?? "None reported")
        Medical Conditions: \(fields["medicalConditions"] ?? "None reported")
        
        I certify that the information provided is accurate and complete.
        
        Client Signature: _________________________
        Date: _________________________
        """
    }
}

/// Aftercare template
struct AftercareTemplate: ConsentFormTemplate {
    let requiredFields = ["clientName", "procedureType", "artistName"]
    let optionalFields = ["email", "phone", "address"]
    
    func validate(fields: [String: String]) -> Bool {
        return requiredFields.allSatisfy { field in
            guard let value = fields[field] else { return false }
            return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    func getContent(for fields: [String: String]) -> String {
        return """
        AFTERCARE INSTRUCTIONS
        
        Client: \(fields["clientName"] ?? "")
        Procedure: \(fields["procedureType"] ?? "")
        Artist: \(fields["artistName"] ?? "")
        
        Please follow these aftercare instructions carefully to ensure proper healing.
        
        Client Signature: _________________________
        Date: _________________________
        """
    }
}
