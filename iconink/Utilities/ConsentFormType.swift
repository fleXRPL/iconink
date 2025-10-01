import Foundation

/// Types of consent forms available in the application
enum ConsentFormType: String, CaseIterable, Codable {
    case tattoo = "Tattoo Consent"
    case piercing = "Piercing Consent"
    case minorConsent = "Minor Consent"
    case medicalHistory = "Medical History"
    case aftercare = "Aftercare Instructions"
    
    var description: String {
        switch self {
        case .tattoo:
            return "Tattoo Consent Form"
        case .piercing:
            return "Piercing Consent Form"
        case .minorConsent:
            return "Minor Consent Form"
        case .medicalHistory:
            return "Medical History Form"
        case .aftercare:
            return "Aftercare Instructions"
        }
    }
    
    var icon: String {
        switch self {
        case .tattoo:
            return "paintbrush"
        case .piercing:
            return "circle.dotted"
        case .minorConsent:
            return "person.2"
        case .medicalHistory:
            return "cross.case"
        case .aftercare:
            return "doc.text"
        }
    }
}
