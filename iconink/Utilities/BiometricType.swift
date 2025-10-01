import Foundation

/// Represents the type of biometric authentication available on the device
enum BiometricType {
    case none
    case touchID
    case faceID
    
    var description: String {
        switch self {
        case .none:
            return "Biometric Authentication"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        }
    }
    
    var systemImage: String {
        switch self {
        case .none:
            return "lock"
        case .touchID:
            return "touchid"
        case .faceID:
            return "faceid"
        }
    }
}
