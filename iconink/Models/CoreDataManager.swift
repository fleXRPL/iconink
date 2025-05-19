import CoreData
import Foundation

/// Manages CoreData operations including CRUD, validation, and migration
class CoreDataManager {
    static let shared = CoreDataManager()
    
    private let container: NSPersistentContainer
    private let modelName = "IconInk"
    private let modelVersion = "1.0"
    
    private init() {
        container = NSPersistentContainer(name: modelName)
        
        // Configure migration options
        let description = NSPersistentStoreDescription()
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        
        // Load persistent stores
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        
        // Configure merge policy
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Context Management
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
    
    // MARK: - CRUD Operations
    
    // MARK: Client Operations
    
    func createClient(name: String, email: String, phone: String?, address: String?) throws -> Client {
        let context = viewContext
        let client = Client(context: context)
        
        client.id = UUID()
        client.name = name
        client.email = email
        client.phone = phone
        client.address = address
        client.createdAt = Date()
        client.updatedAt = Date()
        
        try validateAndSave(context)
        return client
    }
    
    func updateClient(_ client: Client, name: String?, email: String?, phone: String?, address: String?) throws {
        if let name = name { client.name = name }
        if let email = email { client.email = email }
        if let phone = phone { client.phone = phone }
        if let address = address { client.address = address }
        client.updatedAt = Date()
        
        try validateAndSave(viewContext)
    }
    
    func deleteClient(_ client: Client) throws {
        viewContext.delete(client)
        try viewContext.save()
    }
    
    // MARK: ConsentForm Operations
    
    func createConsentForm(title: String, content: String, type: String, client: Client) throws -> ConsentForm {
        let context = viewContext
        let form = ConsentForm(context: context)
        
        form.id = UUID()
        form.title = title
        form.content = content
        form.type = type
        form.createdAt = Date()
        form.updatedAt = Date()
        form.client = client
        
        try validateAndSave(context)
        return form
    }
    
    func updateConsentForm(_ form: ConsentForm, title: String?, content: String?, pdfData: Data?) throws {
        if let title = title { form.title = title }
        if let content = content { form.content = content }
        if let pdfData = pdfData { form.pdfData = pdfData }
        form.updatedAt = Date()
        
        try validateAndSave(viewContext)
    }
    
    func deleteConsentForm(_ form: ConsentForm) throws {
        viewContext.delete(form)
        try viewContext.save()
    }
    
    // MARK: IDScan Operations
    
    func createIDScan(client: Client, frontImage: Data?, backImage: Data?, idType: String, idNumber: String?) throws -> IDScan {
        let context = viewContext
        let scan = IDScan(context: context)
        
        scan.id = UUID()
        scan.frontImage = frontImage
        scan.backImage = backImage
        scan.idType = idType
        scan.idNumber = idNumber
        scan.scanDate = Date()
        scan.createdAt = Date()
        scan.updatedAt = Date()
        scan.client = client
        
        try validateAndSave(context)
        return scan
    }
    
    func updateIDScan(_ scan: IDScan, frontImage: Data?, backImage: Data?, qualityScore: Double?) throws {
        if let frontImage = frontImage { scan.frontImage = frontImage }
        if let backImage = backImage { scan.backImage = backImage }
        if let qualityScore = qualityScore { scan.qualityScore = qualityScore }
        scan.updatedAt = Date()
        
        try validateAndSave(viewContext)
    }
    
    func deleteIDScan(_ scan: IDScan) throws {
        viewContext.delete(scan)
        try viewContext.save()
    }
    
    // MARK: Signature Operations
    
    func createSignature(client: Client, imageData: Data, consentForm: ConsentForm? = nil) throws -> Signature {
        let context = viewContext
        let signature = Signature(context: context)
        
        signature.id = UUID()
        signature.imageData = imageData
        signature.createdAt = Date()
        signature.updatedAt = Date()
        signature.isValid = true
        signature.validationDate = Date()
        signature.client = client
        signature.consentForm = consentForm
        
        try validateAndSave(context)
        return signature
    }
    
    func updateSignature(_ signature: Signature, imageData: Data?, isValid: Bool?) throws {
        if let imageData = imageData { signature.imageData = imageData }
        if let isValid = isValid {
            signature.isValid = isValid
            signature.validationDate = Date()
        }
        signature.updatedAt = Date()
        
        try validateAndSave(viewContext)
    }
    
    func deleteSignature(_ signature: Signature) throws {
        viewContext.delete(signature)
        try viewContext.save()
    }
    
    // MARK: - Validation
    
    private func validateAndSave(_ context: NSManagedObjectContext) throws {
        // Validate email format if present
        if let client = context.insertedObjects.first(where: { $0 is Client }) as? Client,
           let email = client.email {
            guard isValidEmail(email) else {
                throw CoreDataError.validationError("Invalid email format")
            }
        }
        
        // Validate phone format if present
        if let client = context.insertedObjects.first(where: { $0 is Client }) as? Client,
           let phone = client.phone {
            guard isValidPhone(phone) else {
                throw CoreDataError.validationError("Invalid phone format")
            }
        }
        
        // Validate required fields
        for case let form as ConsentForm in context.insertedObjects {
            guard !form.title.isEmpty else {
                throw CoreDataError.validationError("Consent form title is required")
            }
            guard !form.content.isEmpty else {
                throw CoreDataError.validationError("Consent form content is required")
            }
        }
        
        // Save context
        try context.save()
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        let phoneRegEx = "^[+]?[0-9]{10,15}$"
        let phonePred = NSPredicate(format:"SELF MATCHES %@", phoneRegEx)
        return phonePred.evaluate(with: phone)
    }
    
    // MARK: - Backup and Restore
    
    func backupStore() throws -> URL {
        let backupURL = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("IconInk_backup_\(Date().timeIntervalSince1970).sqlite")
        
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            throw CoreDataError.backupError("Store URL not found")
        }
        
        try FileManager.default.copyItem(at: storeURL, to: backupURL)
        return backupURL
    }
    
    func restoreFromBackup(at url: URL) throws {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            throw CoreDataError.restoreError("Store URL not found")
        }
        
        // Remove existing store
        try container.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
        
        // Copy backup to store location
        try FileManager.default.copyItem(at: url, to: storeURL)
        
        // Reload persistent stores
        try container.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
    }
}

// MARK: - Errors

enum CoreDataError: Error {
    case validationError(String)
    case backupError(String)
    case restoreError(String)
    
    var localizedDescription: String {
        switch self {
        case .validationError(let message):
            return "Validation error: \(message)"
        case .backupError(let message):
            return "Backup error: \(message)"
        case .restoreError(let message):
            return "Restore error: \(message)"
        }
    }
} 