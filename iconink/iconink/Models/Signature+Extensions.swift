//
//  Signature+Extensions.swift
//  iconink
//
//  Created by Garot Conklin on 2/27/25.
//

import Foundation
import CoreData
import UIKit

extension Signature {
    // MARK: - Helper Methods
    
    /// Creates a new signature with the given information
    static func createSignature(
        in context: NSManagedObjectContext,
        signatureImage: UIImage,
        signatureType: Int16 = 0,
        consentForm: ConsentForm? = nil
    ) -> Signature {
        // Generate a unique filename
        let fileName = UUID().uuidString + ".png"
        let signaturePath = "Signatures/" + fileName
        
        // Create the Signature object
        let signature = Signature(context: context)
        signature.fileName = fileName
        signature.signaturePath = signaturePath
        signature.captureDate = Date()
        signature.signatureType = signatureType
        signature.consentForm = consentForm
        signature.createdAt = Date()
        
        // Save the signature to disk
        saveSignatureToDisk(image: signatureImage, path: signaturePath)
        
        return signature
    }
    
    /// Saves a signature image to disk
    private static func saveSignatureToDisk(image: UIImage, path: String) {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Unable to access documents directory")
            return
        }
        
        // Create the Signatures directory if it doesn't exist
        let signaturesDirectory = documentsDirectory.appendingPathComponent("Signatures", isDirectory: true)
        if !fileManager.fileExists(atPath: signaturesDirectory.path) {
            do {
                try fileManager.createDirectory(at: signaturesDirectory, withIntermediateDirectories: true)
            } catch {
                print("Error creating Signatures directory: \(error)")
                return
            }
        }
        
        // Save the image with transparency (PNG)
        let fileURL = documentsDirectory.appendingPathComponent(path)
        if let imageData = image.pngData() {
            do {
                try imageData.write(to: fileURL)
            } catch {
                print("Error saving signature: \(error)")
            }
        }
    }
    
    /// Loads the signature image from disk
    func loadSignature() -> UIImage? {
        guard let signaturePath = signaturePath else { return nil }
        
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Unable to access documents directory")
            return nil
        }
        let fileURL = documentsDirectory.appendingPathComponent(signaturePath)
        
        if fileManager.fileExists(atPath: fileURL.path),
           let imageData = try? Data(contentsOf: fileURL),
           let image = UIImage(data: imageData) {
            return image
        }
        
        return nil
    }
    
    /// Deletes the signature file from disk
    func deleteSignatureFile() -> Bool {
        guard let signaturePath = signaturePath else { return false }
        
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Unable to access documents directory")
            return false
        }
        let fileURL = documentsDirectory.appendingPathComponent(signaturePath)
        
        do {
            try fileManager.removeItem(at: fileURL)
            return true
        } catch {
            print("Error deleting signature file: \(error)")
            return false
        }
    }
    
    /// Returns the signature type as a string
    var signatureTypeString: String {
        switch signatureType {
        case 0:
            return "Client"
        case 1:
            return "Artist"
        case 2:
            return "Parent/Guardian"
        case 3:
            return "Witness"
        default:
            return "Unknown"
        }
    }
    
    /// Returns all signatures for a consent form
    static func fetchSignaturesForConsentForm(consentForm: ConsentForm, in context: NSManagedObjectContext) -> [Signature] {
        let request: NSFetchRequest<Signature> = Signature.fetchRequest()
        request.predicate = NSPredicate(format: "consentForm == %@", consentForm)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Signature.captureDate, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching signatures: \(error)")
            return []
        }
    }
} 
