//
//  FileManager+Extensions.swift
//  iconink
//
//  Created by Garot Conklin on 2/27/25.
//

import Foundation
import UIKit

extension FileManager {
    
    /// Application's documents directory URL
    static var documentsDirectory: URL {
        if let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            return directory
        }
        // Fallback to temporary directory if documents directory is unavailable
        return URL(fileURLWithPath: NSTemporaryDirectory())
    }
    
    /// Creates a directory at the specified path if it doesn't exist
    static func createDirectoryIfNeeded(at path: String) -> Bool {
        let fileManager = FileManager.default
        let directoryURL = documentsDirectory.appendingPathComponent(path, isDirectory: true)
        
        if !fileManager.fileExists(atPath: directoryURL.path) {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
                return true
            } catch {
                print("Error creating directory at \(path): \(error)")
                return false
            }
        }
        
        return true // Directory already exists
    }
    
    /// Saves an image to the specified path
    static func saveImage(_ image: UIImage, to path: String, compressionQuality: CGFloat = 0.8) -> Bool {
        let fileManager = FileManager.default
        let fileURL = documentsDirectory.appendingPathComponent(path)
        
        // Create the directory if needed
        let directory = path.components(separatedBy: "/").dropLast().joined(separator: "/")
        if !createDirectoryIfNeeded(at: directory) {
            return false
        }
        
        // Save the image
        do {
            if path.hasSuffix(".jpg") || path.hasSuffix(".jpeg") {
                if let data = image.jpegData(compressionQuality: compressionQuality) {
                    try data.write(to: fileURL)
                    return true
                }
            } else {
                if let data = image.pngData() {
                    try data.write(to: fileURL)
                    return true
                }
            }
        } catch {
            print("Error saving image to \(path): \(error)")
        }
        
        return false
    }
    
    /// Loads an image from the specified path
    static func loadImage(from path: String) -> UIImage? {
        let fileManager = FileManager.default
        let fileURL = documentsDirectory.appendingPathComponent(path)
        
        if fileManager.fileExists(atPath: fileURL.path),
           let data = try? Data(contentsOf: fileURL) {
            return UIImage(data: data)
        }
        
        return nil
    }
    
    /// Deletes a file at the specified path
    static func deleteFile(at path: String) -> Bool {
        let fileManager = FileManager.default
        let fileURL = documentsDirectory.appendingPathComponent(path)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
                return true
            } catch {
                print("Error deleting file at \(path): \(error)")
                return false
            }
        }
        
        return false // File doesn't exist
    }
    
    /// Returns the size of a file at the specified path
    static func fileSize(at path: String) -> Int64? {
        let fileManager = FileManager.default
        let fileURL = documentsDirectory.appendingPathComponent(path)
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            return attributes[.size] as? Int64
        } catch {
            print("Error getting file size for \(path): \(error)")
            return nil
        }
    }
    
    /// Returns a unique filename with the specified extension
    static func uniqueFilename(withExtension ext: String) -> String {
        return UUID().uuidString + "." + ext
    }
    
    /// Returns the total size of a directory
    static func directorySize(at path: String) -> Int64 {
        let fileManager = FileManager.default
        let directoryURL = documentsDirectory.appendingPathComponent(path, isDirectory: true)
        
        guard let enumerator = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        
        for case let fileURL as URL in enumerator {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                totalSize += attributes[.size] as? Int64 ?? 0
            } catch {
                print("Error getting size for \(fileURL.path): \(error)")
            }
        }
        
        return totalSize
    }
    
    /// Returns a formatted string representation of a file size
    static func formattedFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    static func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    static func getAppSupportDirectory() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }
    
    static func ensureDirectoryExists(at url: URL) throws {
        var isDirectory: ObjCBool = false
        if !FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
} 
