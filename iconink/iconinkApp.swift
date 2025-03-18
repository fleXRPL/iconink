import SwiftUI
import CoreData

@main
struct IconInkApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            let context = persistenceController.container.viewContext
            // Create the client entity using a helper function
            let client = createClient(in: context)
            CameraView(isCapturingFront: true, client: client)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
    
    // Helper function to create a client entity
    private func createClient(in context: NSManagedObjectContext) -> NSManagedObject {
        if let entityDescription = NSEntityDescription.entity(forEntityName: "Client", in: context) {
            return NSManagedObject(entity: entityDescription, insertInto: context)
        } else {
            print("Error: Could not find Client entity description")
            return NSManagedObject()
        }
    }
}
