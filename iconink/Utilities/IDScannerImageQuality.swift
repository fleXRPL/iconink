import Foundation
import CoreImage
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Image quality assessment results
enum ImageQuality {
    case good
    case acceptable
    case poor
}

/// Provides image quality assessment for ID scanning
class IDImageQualityAnalyzer {
    
    /// Assesses the quality of an image to determine if it's suitable for text recognition
    /// - Parameter image: The image to assess
    /// - Returns: The quality assessment result
    #if canImport(UIKit)
    static func assessImageQuality(_ image: UIImage) -> ImageQuality {
    #else
    static func assessImageQuality(_ image: NSImage) -> ImageQuality {
    #endif
        // Get image dimensions
        #if canImport(UIKit)
        let width = image.size.width * image.scale
        let height = image.size.height * image.scale
        #else
        let width = image.size.width
        let height = image.size.height
        #endif
        
        // Check resolution
        let minDimension = min(width, height)
        if minDimension < 800 {
            print("Image quality check: Low resolution - \(width) x \(height)")
            return .poor
        }
        
        // Detect blur
        if let blurScore = detectBlur(image: image), blurScore > 0.7 {
            print("Image quality check: High blur score - \(blurScore)")
            return .poor
        }
        
        // Convert to grayscale for analysis
        #if canImport(UIKit)
        guard let ciImage = CIImage(image: image) else {
        #else
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let ciImage = CIImage(cgImage: cgImage) else {
        #endif
            print("Image quality check: Failed to convert to CIImage")
            return .poor
        }
        
        // Check brightness
        if let brightness = getAverageBrightness(ciImage: ciImage) {
            // Too dark or too bright
            if brightness < 0.2 || brightness > 0.9 {
                print("Image quality check: Poor lighting - brightness \(brightness)")
                return .poor
            }
            
            // Acceptable but not ideal
            if brightness < 0.25 || brightness > 0.85 {
                return .acceptable
            }
        }
        
        // If all checks pass, the image is good
        return .good
    }
    
    /// Calculates the average brightness of an image
    /// - Parameter ciImage: The CIImage to analyze
    /// - Returns: Average brightness value between 0 and 1, or nil if calculation fails
    static func getAverageBrightness(ciImage: CIImage) -> Float? {
        // Create a very small thumbnail to get average color
        let context = CIContext(options: nil)
        let scale = max(1, min(ciImage.extent.width, ciImage.extent.height) / 100)
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: 1/scale, y: 1/scale))
        
        // Convert to grayscale
        guard let grayscale = CIFilter(name: "CIPhotoEffectMono", parameters: [kCIInputImageKey: scaledImage])?.outputImage,
              let cgImage = context.createCGImage(grayscale, from: grayscale.extent) else {
            return nil
        }
        
        // Get bitmap data
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = width * 4
        let bitmapSize = bytesPerRow * height
        
        guard let data = calloc(bitmapSize, MemoryLayout<UInt8>.size) else {
            return nil
        }
        defer { free(data) }
        
        // Create bitmap context
        guard let context = CGContext(data: data,
                                     width: width,
                                     height: height,
                                     bitsPerComponent: 8,
                                     bytesPerRow: bytesPerRow,
                                     space: CGColorSpaceCreateDeviceRGB(),
                                     bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        
        // Draw image in context
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(cgImage, in: rect)
        
        // Calculate average brightness
        var totalBrightness: Float = 0
        let buffer = data.assumingMemoryBound(to: UInt8.self)
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                // Average RGB components
                let brightness = (Float(buffer[offset]) + Float(buffer[offset + 1]) + Float(buffer[offset + 2])) / (3.0 * 255.0)
                totalBrightness += brightness
            }
        }
        
        return totalBrightness / Float(width * height)
    }
    
    /// Detects the amount of blur in an image
    /// - Parameter image: The image to analyze
    /// - Returns: Blur score between 0 and 1 (higher means more blurry), or nil if detection fails
    #if canImport(UIKit)
    static func detectBlur(image: UIImage) -> Float? {
    #else
    static func detectBlur(image: NSImage) -> Float? {
    #endif
        #if canImport(UIKit)
        guard let cgImage = image.cgImage else { return nil }
        #else
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        #endif
        
        // Convert to grayscale
        let context = CIContext(options: nil)
        let ciImage = CIImage(cgImage: cgImage)
        guard let grayscale = CIFilter(name: "CIPhotoEffectMono", parameters: [kCIInputImageKey: ciImage])?.outputImage,
              let grayCGImage = context.createCGImage(grayscale, from: grayscale.extent) else {
            return nil
        }
        
        // Create an edge detection filter (Laplacian)
        let inputImage = CIImage(cgImage: grayCGImage)
        let edgeFilter = CIFilter(name: "CIEdges")
        edgeFilter?.setValue(inputImage, forKey: kCIInputImageKey)
        edgeFilter?.setValue(5.0, forKey: "inputIntensity") // Increase this value for more sensitivity
        
        guard let edgeOutput = edgeFilter?.outputImage,
              let edgeCGImage = context.createCGImage(edgeOutput, from: edgeOutput.extent) else {
            return nil
        }
        
        // Calculate standard deviation of edge image
        var total: Float = 0
        var squaredTotal: Float = 0
        var count: Int = 0
        
        // Create a bitmap for the edge image
        let width = edgeCGImage.width
        let height = edgeCGImage.height
        let bytesPerRow = width * 4
        let bitmapSize = bytesPerRow * height
        
        guard let data = calloc(bitmapSize, MemoryLayout<UInt8>.size) else {
            return nil
        }
        defer { free(data) }
        
        // Create bitmap context
        guard let bitmapContext = CGContext(data: data,
                                          width: width,
                                          height: height,
                                          bitsPerComponent: 8,
                                          bytesPerRow: bytesPerRow,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        
        // Draw edge image in context
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        bitmapContext.draw(edgeCGImage, in: rect)
        
        // Calculate standard deviation
        let buffer = data.assumingMemoryBound(to: UInt8.self)
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                let value = Float(buffer[offset]) // Use the red channel
                total += value
                squaredTotal += value * value
                count += 1
            }
        }
        
        if count == 0 {
            return nil
        }
        
        let mean = total / Float(count)
        let variance = (squaredTotal / Float(count)) - (mean * mean)
        let standardDeviation = sqrt(variance)
        
        // Normalize standard deviation to a 0-1 score where 0 is not blurry and 1 is very blurry
        // Inverse relationship: higher standard deviation means less blur
        let maxSD: Float = 50.0 // Adjust this based on empirical testing
        let blurScore = max(0, min(1, 1.0 - (standardDeviation / maxSD)))
        
        return blurScore
    }
}
