import Foundation
import CoreData

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
    
    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
}

extension Client {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Client> {
        return NSFetchRequest<Client>(entityName: "Client")
    }
}
