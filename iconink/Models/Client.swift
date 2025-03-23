import Foundation
import CoreData
import UIKit

@objc(Client)
public class Client: NSManagedObject, Identifiable {
    @NSManaged public var frontIdPhoto: Data?
    @NSManaged public var backIdPhoto: Data?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var email: String?
    @NSManaged public var phone: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var signature: Data?
    @NSManaged public var consentForms: NSSet?
    
    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    // Computed properties for ID images
    var idFrontImage: UIImage? {
        guard let data = frontIdPhoto else { return nil }
        return UIImage(data: data)
    }
    
    var idBackImage: UIImage? {
        guard let data = backIdPhoto else { return nil }
        return UIImage(data: data)
    }
    
    // Computed property for signature image
    var signatureImage: UIImage? {
        guard let data = signature else { return nil }
        return UIImage(data: data)
    }
    
    // Computed property for full name
    var fullName: String {
        return name ?? "Unknown Client"
    }
}

extension Client {
    /// Fetches Client entities from Core Data
    /// - Returns: An NSFetchRequest configured for Client entities
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Client> {
        return NSFetchRequest<Client>(entityName: "Client")
    }
    
    // Computed properties for compatibility with views
    var firstName: String? {
        get {
            guard let fullName = name else { return nil }
            let parts = fullName.components(separatedBy: " ")
            return parts.first
        }
        set {
            if let existingLast = lastName, let newFirst = newValue {
                name = "\(newFirst) \(existingLast)"
            } else {
                name = newValue
            }
        }
    }
    
    var lastName: String? {
        get {
            guard let fullName = name else { return nil }
            let parts = fullName.components(separatedBy: " ")
            return parts.count > 1 ? parts.last : nil
        }
        set {
            if let existingFirst = firstName, let newLast = newValue {
                name = "\(existingFirst) \(newLast)"
            } else {
                name = newValue
            }
        }
    }
    
    var idFrontImage: UIImage? {
        guard let data = frontIdPhoto else { return nil }
        return UIImage(data: data)
    }
    
    var idBackImage: UIImage? {
        guard let data = backIdPhoto else { return nil }
        return UIImage(data: data)
    }
    
    var fullName: String {
        guard let name = name else { return "Unknown" }
        return name
    }
}
