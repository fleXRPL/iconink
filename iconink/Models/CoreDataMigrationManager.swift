import CoreData
import Foundation

/// Manages CoreData model migrations and versioning
class CoreDataMigrationManager {
    static let shared = CoreDataMigrationManager()
    
    private let modelName = "IconInk"
    private let modelExtension = "momd"
    
    private init() {}
    
    // MARK: - Migration
    
    /// Checks if migration is needed for the current model
    /// - Returns: True if migration is needed, false otherwise
    func requiresMigration(at storeURL: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return false
        }
        
        guard let metadata = try? NSPersistentStoreCoordinator.metadata(at: storeURL) else {
            return false
        }
        
        return !isCompatible(metadata: metadata)
    }
    
    /// Performs migration if needed
    /// - Parameter storeURL: URL of the store to migrate
    /// - Returns: URL of the migrated store
    func migrateStore(at storeURL: URL) throws -> URL {
        guard requiresMigration(at: storeURL) else {
            return storeURL
        }
        
        // Get the current model version
        guard let currentModel = try? managedObjectModel() else {
            throw MigrationError.modelNotFound
        }
        
        // Get the source model version
        guard let sourceModel = try? sourceModel(for: storeURL) else {
            throw MigrationError.sourceModelNotFound
        }
        
        // Create a temporary URL for the migrated store
        let tempURL = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("IconInk_migrated.sqlite")
        
        // Remove any existing file at the temporary URL
        if FileManager.default.fileExists(atPath: tempURL.path) {
            try FileManager.default.removeItem(at: tempURL)
        }
        
        // Perform the migration
        let manager = NSMigrationManager(sourceModel: sourceModel, destinationModel: currentModel)
        let mapping = try NSMappingModel(from: nil, forSourceModel: sourceModel, destinationModel: currentModel)
        
        try manager.migrateStore(
            from: storeURL,
            sourceType: NSSQLiteStoreType,
            options: nil,
            with: mapping,
            toDestinationURL: tempURL,
            destinationType: NSSQLiteStoreType,
            destinationOptions: nil
        )
        
        // Replace the original store with the migrated one
        try FileManager.default.removeItem(at: storeURL)
        try FileManager.default.moveItem(at: tempURL, to: storeURL)
        
        return storeURL
    }
    
    // MARK: - Private Helpers
    
    private func managedObjectModel() throws -> NSManagedObjectModel {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: modelExtension) else {
            throw MigrationError.modelNotFound
        }
        
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw MigrationError.modelLoadFailed
        }
        
        return model
    }
    
    private func sourceModel(for storeURL: URL) throws -> NSManagedObjectModel {
        guard let metadata = try? NSPersistentStoreCoordinator.metadata(at: storeURL),
              let sourceModel = NSManagedObjectModel.mergedModel(from: [Bundle.main], forStoreMetadata: metadata) else {
            throw MigrationError.sourceModelNotFound
        }
        
        return sourceModel
    }
    
    private func isCompatible(metadata: [String: Any]) -> Bool {
        guard let currentModel = try? managedObjectModel() else {
            return false
        }
        
        return currentModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
    }
}

// MARK: - Errors

enum MigrationError: Error {
    case modelNotFound
    case modelLoadFailed
    case sourceModelNotFound
    case migrationFailed
    
    var localizedDescription: String {
        switch self {
        case .modelNotFound:
            return "Core Data model not found"
        case .modelLoadFailed:
            return "Failed to load Core Data model"
        case .sourceModelNotFound:
            return "Source model not found for migration"
        case .migrationFailed:
            return "Migration failed"
        }
    }
} 