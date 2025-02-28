//
//  IDImage+Extensions.swift
//  iconink
//
//  Created by Garot Conklin on 2/27/25.
//

import Foundation
import CoreData
import UIKit

extension IDImage {
    // MARK: - Helper Methods
    
    /// Creates a new ID image with the given information
    static func createIDImage(
        in context: NSManagedObjectContext,
        image: UIImage,
        imageType: Int16 = 0,
        client: Client? = nil
    ) -> IDImage {
        // Generate a unique filename
        let fileName = UUID().uuidString + ".jpg"
        let imagePath = "IDImages/" + fileName
        
        // Create the IDImage object
        let idImage = IDImage(context: context)
        idImage.fileName = fileName
        idImage.imagePath = imagePath
        idImage.captureDate = Date()
        idImage.imageType = imageType
        idImage.client = client
        idImage.createdAt = Date()
        
        // Save the image to disk
        saveImageToDisk(image: image, path: imagePath)
        
        return idImage
    }
    
    /// Saves an image to disk
    private static func saveImageToDisk(image: UIImage, path: String) {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Unable to access documents directory")
            return
        }
        
        // Create the IDImages directory if it doesn't exist
        let imagesDirectory = documentsDirectory.appendingPathComponent("IDImages", isDirectory: true)
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            do {
                try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
            } catch {
                print("Error creating IDImages directory: \(error)")
                return
            }
        }
        
        // Save the image
        let fileURL = documentsDirectory.appendingPathComponent(path)
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            do {
                try imageData.write(to: fileURL)
            } catch {
                print("Error saving image: \(error)")
            }
        }
    }
    
    /// Loads the ID image from disk
    func loadImage() -> UIImage? {
        guard let imagePath = imagePath else { return nil }
        
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Unable to access documents directory")
            return nil
        }
        let fileURL = documentsDirectory.appendingPathComponent(imagePath)
        
        if fileManager.fileExists(atPath: fileURL.path),
           let imageData = try? Data(contentsOf: fileURL),
           let image = UIImage(data: imageData) {
            return image
        }
        
        return nil
    }
    
    /// Deletes the image file from disk
    func deleteImageFile() -> Bool {
        guard let imagePath = imagePath else { return false }
        
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Unable to access documents directory")
            return false
        }
        let fileURL = documentsDirectory.appendingPathComponent(imagePath)
        
        do {
            try fileManager.removeItem(at: fileURL)
            return true
        } catch {
            print("Error deleting image file: \(error)")
            return false
        }
    }
    
    /// Returns the image type as a string
    var imageTypeString: String {
        switch imageType {
        case 0:
            return "Front Side"
        case 1:
            return "Back Side"
        case 2:
            return "Selfie with ID"
        case 3:
            return "Other"
        default:
            return "Unknown"
        }
    }
    
    /// Returns all ID images for a client
    static func fetchIDImagesForClient(client: Client, in context: NSManagedObjectContext) -> [IDImage] {
        let request: NSFetchRequest<IDImage> = IDImage.fetchRequest()
        request.predicate = NSPredicate(format: "client == %@", client)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \IDImage.captureDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching ID images: \(error)")
            return []
        }
    }
    
    /// Updates the ID image with OCR extracted data
    func updateWithExtractedData(
        name: String? = nil,
        dob: Date? = nil,
        address: String? = nil,
        idNumber: String? = nil,
        expirationDate: Date? = nil,
        state: String? = nil,
        confidence: Double? = nil
    ) {
        self.extractedName = name
        self.extractedDOB = dob
        self.extractedAddress = address
        self.extractedIDNumber = idNumber
        self.extractedExpirationDate = expirationDate
        self.extractedState = state
        self.extractionConfidence = confidence ?? 0.0
    }
} 
