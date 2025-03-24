import CoreData

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    private(set) var isStoreLoaded = false
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "IconInk")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, 
            forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        loadStores()
    }
    
    func loadStores() {
        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                print("CoreData error: \(error.localizedDescription)")
                print("Failed to load persistent stores. Model configuration or migration may have failed.")
                self?.isStoreLoaded = false
            } else {
                self?.isStoreLoaded = true
                print("CoreData: Successfully loaded persistent stores")
                
                // Initialize the view context
                self?.configureViewContext()
            }
        }
    }
    
    private func configureViewContext() {
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // Helper to create a client entity
    func createClientEntity(in context: NSManagedObjectContext) -> NSManagedObject? {
        let entityName = "Client"
        
        guard let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
            print("Could not find entity description for '\(entityName)'")
            return nil
        }
        
        let client = NSManagedObject(entity: entityDescription, insertInto: context)
        client.setValue(UUID(), forKey: "id")
        client.setValue(Date(), forKey: "createdAt")
        
        return client
    }
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Add preview data - create a sample client
        if let client = result.createClientEntity(in: viewContext) {
            client.setValue("John Doe", forKey: "name")
            client.setValue("555-1234", forKey: "phone")
            client.setValue("john@example.com", forKey: "email")
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error creating preview data: \(nsError)")
        }
        
        return result
    }()
}
