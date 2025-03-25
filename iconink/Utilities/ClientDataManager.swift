import Foundation
import CoreData
import SwiftUI

/// Manages the export and import of client data
class ClientDataManager {
    
    /// Error types for data operations
    enum DataOperationError: Error {
        case encodingFailed
        case decodingFailed
        case fileWriteFailed
        case fileReadFailed
        case invalidData
        case accessDenied
    }
    
    /// Export client data to a JSON file
    /// - Parameters:
    ///   - clients: Array of clients to export
    ///   - encryptData: Whether to encrypt the exported data
    /// - Returns: URL to the exported file or nil if export failed
    static func exportClients(_ clients: [Client], encryptData: Bool) -> Result<URL, DataOperationError> {
        do {
            // Create a serializable representation of clients
            var clientsData: [[String: Any]] = []
            
            for client in clients {
                var clientDict: [String: Any] = [
                    "id": client.id?.uuidString ?? UUID().uuidString,
                    "name": client.name ?? "",
                    "createdAt": client.createdAt ?? Date(),
                    "updatedAt": client.updatedAt ?? Date()
                ]
                
                // Add optional fields if they exist
                if let email = client.email {
                    clientDict["email"] = email
                }
                
                if let phone = client.phone {
                    clientDict["phone"] = phone
                }
                
                if let frontIdPhoto = client.frontIdPhoto {
                    clientDict["frontIdPhoto"] = frontIdPhoto
                }
                
                if let backIdPhoto = client.backIdPhoto {
                    clientDict["backIdPhoto"] = backIdPhoto
                }
                
                if let signature = client.signature {
                    clientDict["signature"] = signature
                }
                
                if let address = client.address {
                    clientDict["address"] = address
                }
                
                if let idNumber = client.idNumber {
                    clientDict["idNumber"] = idNumber
                }
                
                // Add consent forms if available
                if let forms = client.consentForms as? Set<ConsentForm>, !forms.isEmpty {
                    var formsArray: [[String: Any]] = []
                    
                    for form in forms {
                        var formDict: [String: Any] = [
                            "title": form.title,
                            "content": form.content,
                            "dateCreated": form.dateCreated
                        ]
                        
                        if let signature = form.signature {
                            formDict["signature"] = signature
                        }
                        
                        formsArray.append(formDict)
                    }
                    
                    clientDict["consentForms"] = formsArray
                }
                
                clientsData.append(clientDict)
            }
            
            // Convert to JSON data
            let jsonData: Data
            
            if #available(iOS 15.0, *) {
                jsonData = try JSONSerialization.data(withJSONObject: clientsData, options: [.prettyPrinted, .sortedKeys])
            } else {
                jsonData = try JSONSerialization.data(withJSONObject: clientsData, options: [.prettyPrinted])
            }
            
            // Encrypt data if needed
            let dataToWrite: Data
            if encryptData {
                if let encryptedData = SecurityManager.shared.encryptData(jsonData) {
                    dataToWrite = encryptedData
                } else {
                    return .failure(.encodingFailed)
                }
            } else {
                dataToWrite = jsonData
            }
            
            // Create unique filename with timestamp
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let dateString = dateFormatter.string(from: Date())
            let fileName = "iconink_clients_\(dateString).json"
            
            // Get Documents directory URL
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return .failure(.fileWriteFailed)
            }
            
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            // Write data to file
            try dataToWrite.write(to: fileURL, options: .atomic)
            
            return .success(fileURL)
        } catch {
            print("Export error: \(error)")
            return .failure(.fileWriteFailed)
        }
    }
    
    /// Import clients from a JSON file
    /// - Parameters:
    ///   - url: URL of the file to import
    ///   - context: The managed object context to create entities in
    ///   - isEncrypted: Whether the file is encrypted
    /// - Returns: Array of imported clients or error
    static func importClients(from url: URL, context: NSManagedObjectContext, isEncrypted: Bool) -> Result<[Client], DataOperationError> {
        do {
            // Read data from file
            let fileData = try Data(contentsOf: url)
            
            // Decrypt data if needed
            let jsonData: Data
            if isEncrypted {
                if let decryptedData = SecurityManager.shared.decryptData(fileData) {
                    jsonData = decryptedData
                } else {
                    return .failure(.decodingFailed)
                }
            } else {
                jsonData = fileData
            }
            
            // Parse JSON data
            guard let clientsArray = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] else {
                return .failure(.invalidData)
            }
            
            // Create Client entities
            var importedClients: [Client] = []
            
            for clientDict in clientsArray {
                let client = Client(context: context)
                
                // Set required properties
                if let idString = clientDict["id"] as? String {
                    client.id = UUID(uuidString: idString) ?? UUID()
                } else {
                    client.id = UUID()
                }
                
                if let name = clientDict["name"] as? String {
                    client.name = name
                }
                
                if let createdAt = clientDict["createdAt"] as? Date {
                    client.createdAt = createdAt
                } else {
                    client.createdAt = Date()
                }
                
                if let updatedAt = clientDict["updatedAt"] as? Date {
                    client.updatedAt = updatedAt
                } else {
                    client.updatedAt = Date()
                }
                
                // Set optional properties if they exist
                if let email = clientDict["email"] as? String {
                    client.email = email
                }
                
                if let phone = clientDict["phone"] as? String {
                    client.phone = phone
                }
                
                if let frontIdPhoto = clientDict["frontIdPhoto"] as? Data {
                    client.frontIdPhoto = frontIdPhoto
                }
                
                if let backIdPhoto = clientDict["backIdPhoto"] as? Data {
                    client.backIdPhoto = backIdPhoto
                }
                
                if let signature = clientDict["signature"] as? Data {
                    client.signature = signature
                }
                
                if let address = clientDict["address"] as? String {
                    client.address = address
                }
                
                if let idNumber = clientDict["idNumber"] as? String {
                    client.idNumber = idNumber
                }
                
                // Import consent forms if available
                if let formsArray = clientDict["consentForms"] as? [[String: Any]] {
                    for formDict in formsArray {
                        let form = ConsentForm(context: context)
                        
                        if let title = formDict["title"] as? String {
                            form.title = title
                        } else {
                            form.title = "Untitled Form"
                        }
                        
                        if let content = formDict["content"] as? String {
                            form.content = content
                        } else {
                            form.content = ""
                        }
                        
                        if let dateCreated = formDict["dateCreated"] as? Date {
                            form.dateCreated = dateCreated
                        } else {
                            form.dateCreated = Date()
                        }
                        
                        if let signature = formDict["signature"] as? Data {
                            form.signature = signature
                        }
                        
                        form.client = client
                    }
                }
                
                importedClients.append(client)
            }
            
            try context.save()
            return .success(importedClients)
        } catch {
            print("Import error: \(error)")
            if let coreDataError = error as NSError? {
                print("Core Data error: \(coreDataError), \(coreDataError.userInfo)")
            }
            return .failure(.fileReadFailed)
        }
    }
    
    /// Share exported data file
    /// - Parameters:
    ///   - fileURL: URL of the file to share
    ///   - presenter: UIViewController to present the share sheet from
    #if canImport(UIKit)
    static func shareExportedFile(fileURL: URL, presenter: UIViewController) {
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        presenter.present(activityVC, animated: true)
    }
    #endif
} 