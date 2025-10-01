import Foundation
import CoreData
import UIKit

/// Error types for data management operations
enum DataManagementError: Error {
    case fileReadFailed
    case fileWriteFailed
    case decodingFailed
    case encodingFailed
    case invalidData
    case encryptionFailed
    case decryptionFailed
    
    var localizedDescription: String {
        switch self {
        case .fileReadFailed:
            return "Failed to read file"
        case .fileWriteFailed:
            return "Failed to write file"
        case .decodingFailed:
            return "Failed to decode data"
        case .encodingFailed:
            return "Failed to encode data"
        case .invalidData:
            return "Invalid data format"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        }
    }
}

/// Manages client data export and import operations
class ClientDataManager {
    
    /// Exports client data to a file
    /// - Parameters:
    ///   - clients: Array of clients to export
    ///   - encryptData: Whether to encrypt the exported data
    /// - Returns: Result containing the file URL or error
    static func exportClients(_ clients: [Client], encryptData: Bool = false) -> Result<URL, DataManagementError> {
        do {
            // Convert clients to exportable format
            let exportData = clients.map { client in
                ClientExportData(
                    id: client.id?.uuidString ?? "",
                    name: client.name ?? "",
                    email: client.email,
                    phone: client.phone,
                    address: client.address,
                    createdAt: client.createdAt,
                    updatedAt: client.updatedAt,
                    frontIdPhoto: client.frontIdPhoto,
                    backIdPhoto: client.backIdPhoto,
                    signature: client.signature
                )
            }
            
            // Encode to JSON
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(exportData)
            
            // Encrypt if requested
            let finalData: Data
            if encryptData {
                guard let encryptedData = SecurityManager.shared.encryptData(jsonData) else {
                    return .failure(.encryptionFailed)
                }
                finalData = encryptedData
            } else {
                finalData = jsonData
            }
            
            // Save to file
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "IconInk_Export_\(Date().timeIntervalSince1970).json"
            let fileURL = documentsPath.appendingPathComponent(fileName)
            
            try finalData.write(to: fileURL)
            
            return .success(fileURL)
        } catch {
            return .failure(.encodingFailed)
        }
    }
    
    /// Imports client data from a file
    /// - Parameters:
    ///   - url: URL of the file to import
    ///   - context: Core Data context
    ///   - isEncrypted: Whether the data is encrypted
    /// - Returns: Result containing imported clients or error
    static func importClients(from url: URL, context: NSManagedObjectContext, isEncrypted: Bool = false) -> Result<[Client], DataManagementError> {
        do {
            // Read file data
            let fileData = try Data(contentsOf: url)
            
            // Decrypt if needed
            let jsonData: Data
            if isEncrypted {
                guard let decryptedData = SecurityManager.shared.decryptData(fileData) else {
                    return .failure(.decryptionFailed)
                }
                jsonData = decryptedData
            } else {
                jsonData = fileData
            }
            
            // Decode JSON
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let importData = try decoder.decode([ClientExportData].self, from: jsonData)
            
            // Create clients in Core Data
            var importedClients: [Client] = []
            for clientData in importData {
                let client = Client(context: context)
                client.id = UUID(uuidString: clientData.id) ?? UUID()
                client.name = clientData.name
                client.email = clientData.email
                client.phone = clientData.phone
                client.address = clientData.address
                client.createdAt = clientData.createdAt ?? Date()
                client.updatedAt = clientData.updatedAt ?? Date()
                client.frontIdPhoto = clientData.frontIdPhoto
                client.backIdPhoto = clientData.backIdPhoto
                client.signature = clientData.signature
                
                importedClients.append(client)
            }
            
            // Save context
            try context.save()
            
            return .success(importedClients)
        } catch {
            return .failure(.decodingFailed)
        }
    }
    
    /// Shares an exported file
    /// - Parameters:
    ///   - fileURL: URL of the file to share
    ///   - presenter: View controller to present the share sheet
    static func shareExportedFile(fileURL: URL, presenter: UIViewController) {
        let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        
        // Configure for iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        presenter.present(activityViewController, animated: true)
    }
}

/// Data structure for client export/import
struct ClientExportData: Codable {
    let id: String
    let name: String
    let email: String?
    let phone: String?
    let address: String?
    let createdAt: Date?
    let updatedAt: Date?
    let frontIdPhoto: Data?
    let backIdPhoto: Data?
    let signature: Data?
}