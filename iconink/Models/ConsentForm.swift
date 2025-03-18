import Foundation
import CoreData

// Forward reference
@objc(Client)
class ClientRef: NSManagedObject { }

@objc(ConsentForm)
public class ConsentForm: NSManagedObject, Identifiable {
    @NSManaged public var title: String
    @NSManaged public var content: String
    @NSManaged public var signature: Data?
    @NSManaged public var dateCreated: Date
    @NSManaged public var client: ClientRef?
}

extension ConsentForm {
    static func fetchRequest() -> NSFetchRequest<ConsentForm> {
        return NSFetchRequest<ConsentForm>(entityName: "ConsentForm")
    }
} 
