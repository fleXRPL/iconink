import Foundation

/// Represents different types of consent forms
enum ConsentFormType: String, CaseIterable {
    case tattoo = "Tattoo Consent"
    case piercing = "Piercing Consent"
    case minorConsent = "Minor Consent"
    case medicalHistory = "Medical History"
    case aftercare = "Aftercare Instructions"
    
    var templateName: String {
        switch self {
        case .tattoo: return "tattoo_consent_template"
        case .piercing: return "piercing_consent_template"
        case .minorConsent: return "minor_consent_template"
        case .medicalHistory: return "medical_history_template"
        case .aftercare: return "aftercare_template"
        }
    }
}

/// Manages consent form templates
struct ConsentFormTemplate {
    let type: ConsentFormType
    let content: String
    let requiredFields: [String]
    let version: String
    
    /// Validates if all required fields are filled
    func validate(fields: [String: String]) -> Bool {
        return requiredFields.allSatisfy { fields[$0] != nil && !fields[$0]!.isEmpty }
    }
    
    /// Returns a list of missing required fields
    func missingFields(fields: [String: String]) -> [String] {
        return requiredFields.filter { fields[$0]?.isEmpty ?? true }
    }
}

/// Provides access to consent form templates
class ConsentFormTemplateManager {
    static let shared = ConsentFormTemplateManager()
    
    private init() {}
    
    /// Returns the template for a given form type
    func template(for type: ConsentFormType) -> ConsentFormTemplate {
        // In a real app, these would be loaded from files or a database
        switch type {
        case .tattoo:
            return ConsentFormTemplate(
                type: type,
                content: tattooConsentTemplate,
                requiredFields: [
                    "clientName",
                    "dateOfBirth",
                    "address",
                    "phone",
                    "email",
                    "designDescription",
                    "bodyLocation",
                    "artistName"
                ],
                version: "1.0"
            )
            
        case .piercing:
            return ConsentFormTemplate(
                type: type,
                content: piercingConsentTemplate,
                requiredFields: [
                    "clientName",
                    "dateOfBirth",
                    "address",
                    "phone",
                    "email",
                    "piercingLocation",
                    "jewelryType",
                    "piercerName"
                ],
                version: "1.0"
            )
            
        case .minorConsent:
            return ConsentFormTemplate(
                type: type,
                content: minorConsentTemplate,
                requiredFields: [
                    "minorName",
                    "minorDateOfBirth",
                    "guardianName",
                    "guardianID",
                    "relationship",
                    "contactPhone",
                    "procedure"
                ],
                version: "1.0"
            )
            
        case .medicalHistory:
            return ConsentFormTemplate(
                type: type,
                content: medicalHistoryTemplate,
                requiredFields: [
                    "clientName",
                    "dateOfBirth",
                    "allergies",
                    "medications",
                    "medicalConditions",
                    "bloodType"
                ],
                version: "1.0"
            )
            
        case .aftercare:
            return ConsentFormTemplate(
                type: type,
                content: aftercareTemplate,
                requiredFields: [
                    "clientName",
                    "procedureType",
                    "procedureDate",
                    "artistName"
                ],
                version: "1.0"
            )
        }
    }
}

// MARK: - Template Content
private let tattooConsentTemplate = """
TATTOO CONSENT FORM

Date: {date}
Artist Name: {artistName}

CLIENT INFORMATION
Name: {clientName}
Date of Birth: {dateOfBirth}
Address: {address}
Phone: {phone}
Email: {email}

PROCEDURE DETAILS
Design Description: {designDescription}
Body Location: {bodyLocation}

CONSENT AND ACKNOWLEDGMENT
I, {clientName}, being of sound mind and body, do hereby consent to receive a tattoo. 
I acknowledge that I have been fully informed of the risks associated with getting a tattoo, including but not limited to:

1. Infection
2. Allergic reactions
3. Scarring
4. Blood loss
5. Pain during and after the procedure

I confirm that:
- I am not under the influence of alcohol or drugs
- I am not pregnant or nursing
- I do not have any medical conditions that may interfere with the healing process
- I have disclosed all relevant medical information to my artist

I understand that the success and longevity of my tattoo depends on my proper aftercare and following the provided instructions.

Client Signature: {clientSignature}
Date: {date}

Artist Signature: {artistSignature}
Date: {date}
"""

private let piercingConsentTemplate = """
PIERCING CONSENT FORM

Date: {date}
Piercer Name: {piercerName}

CLIENT INFORMATION
Name: {clientName}
Date of Birth: {dateOfBirth}
Address: {address}
Phone: {phone}
Email: {email}

PROCEDURE DETAILS
Piercing Location: {piercingLocation}
Jewelry Type: {jewelryType}

CONSENT AND ACKNOWLEDGMENT
I, {clientName}, consent to receive a body piercing. I understand the risks involved, including:

1. Infection
2. Allergic reactions
3. Rejection
4. Scarring
5. Healing complications

I confirm that:
- I am not under the influence of alcohol or drugs
- I am not pregnant or nursing
- I have no medical conditions that may affect healing
- I will follow all aftercare instructions

Client Signature: {clientSignature}
Date: {date}

Piercer Signature: {piercerSignature}
Date: {date}
"""

private let minorConsentTemplate = """
MINOR CONSENT FORM

Date: {date}

MINOR INFORMATION
Name: {minorName}
Date of Birth: {minorDateOfBirth}

LEGAL GUARDIAN INFORMATION
Guardian Name: {guardianName}
Relationship to Minor: {relationship}
ID Number: {guardianID}
Contact Phone: {contactPhone}

PROCEDURE DETAILS
Type of Procedure: {procedure}

PARENTAL CONSENT
I, {guardianName}, as the legal guardian of {minorName}, hereby grant permission for the above procedure.
I understand all risks associated with this procedure and take full responsibility.

Guardian Signature: {guardianSignature}
Date: {date}

Witness Signature: {witnessSignature}
Date: {date}
"""

private let medicalHistoryTemplate = """
MEDICAL HISTORY FORM

Date: {date}

CLIENT INFORMATION
Name: {clientName}
Date of Birth: {dateOfBirth}

MEDICAL INFORMATION
Blood Type: {bloodType}
Allergies: {allergies}
Current Medications: {medications}
Medical Conditions: {medicalConditions}

ACKNOWLEDGMENT
I confirm that the information provided above is accurate and complete.

Client Signature: {clientSignature}
Date: {date}
"""

private let aftercareTemplate = """
AFTERCARE INSTRUCTIONS

Client Name: {clientName}
Procedure Type: {procedureType}
Procedure Date: {procedureDate}
Artist Name: {artistName}

CARE INSTRUCTIONS
1. Keep the area clean and dry
2. Follow specific cleaning instructions provided
3. Avoid swimming, sun exposure, and tight clothing
4. Contact us immediately if you notice any signs of infection

I acknowledge that I have received and understand these aftercare instructions.

Client Signature: {clientSignature}
Date: {date}
""" 