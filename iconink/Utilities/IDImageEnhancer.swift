import Foundation
import CoreImage.CIFilterBuiltins
#if canImport(UIKit)
import UIKit
typealias ImageType = UIImage
#else
import AppKit
typealias ImageType = NSImage
#endif

/// Utility for enhancing images before OCR processing
class IDImageEnhancer {
    
    /// Enhanced image processing results
    enum EnhancementResult {
        case success(image: ImageType)
        case failure(error: Error)
    }
    
    /// Error types for image enhancement
    enum EnhancementError: Error {
        case imageConversionFailed
        case filterProcessingFailed
        case outputCreationFailed
    }
    
    /// Enhances an image for better OCR results
    /// - Parameter image: The image to enhance
    /// - Returns: An enhanced image or error
    static func enhanceForOCR(_ image: ImageType) -> EnhancementResult {
        // Convert to CIImage
        #if canImport(UIKit)
        guard let ciImage = CIImage(image: image) else {
            return .failure(error: EnhancementError.imageConversionFailed)
        }
        #else
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let ciImage = CIImage(cgImage: cgImage) else {
            return .failure(error: EnhancementError.imageConversionFailed)
        }
        #endif
        
        // Create context
        let context = CIContext(options: nil)
        
        do {
            // Apply a series of filters to enhance text readability
            let enhancedImage = try applyEnhancementFilters(to: ciImage, context: context)
            return .success(image: enhancedImage)
        } catch {
            return .failure(error: error)
        }
    }
    
    /// Applies a series of image enhancement filters
    /// - Parameters:
    ///   - inputImage: The CIImage to enhance
    ///   - context: CIContext for rendering
    /// - Returns: An enhanced UIImage/NSImage
    private static func applyEnhancementFilters(to inputImage: CIImage, context: CIContext) throws -> ImageType {
        // 1. Enhance contrast and sharpness
        let contrastFilter = CIFilter.colorControls()
        contrastFilter.inputImage = inputImage
        contrastFilter.contrast = 1.1  // Slightly increase contrast
        contrastFilter.saturation = 0.0  // Remove color (grayscale)
        contrastFilter.brightness = 0.1  // Slightly increase brightness
        
        guard let contrastOutput = contrastFilter.outputImage else {
            throw EnhancementError.filterProcessingFailed
        }
        
        // 2. Apply unsharp mask for sharpening
        let unsharpFilter = CIFilter.unsharpMask()
        unsharpFilter.inputImage = contrastOutput
        unsharpFilter.radius = 1.5  // Radius of effect
        unsharpFilter.intensity = 0.5  // Intensity of effect
        
        guard let sharpenedOutput = unsharpFilter.outputImage else {
            throw EnhancementError.filterProcessingFailed
        }
        
        // 3. Apply noise reduction
        let noiseReductionFilter = CIFilter.noiseReduction()
        noiseReductionFilter.inputImage = sharpenedOutput
        noiseReductionFilter.noiseLevel = 0.02  // Level of noise to reduce
        noiseReductionFilter.sharpness = 0.4  // Preserve edges
        
        guard let denoisedOutput = noiseReductionFilter.outputImage else {
            throw EnhancementError.filterProcessingFailed
        }
        
        // 4. Convert to CGImage
        guard let outputCGImage = context.createCGImage(denoisedOutput, from: denoisedOutput.extent) else {
            throw EnhancementError.outputCreationFailed
        }
        
        // 5. Convert to platform-specific image type
        #if canImport(UIKit)
        return UIImage(cgImage: outputCGImage)
        #else
        let size = NSSize(width: outputCGImage.width, height: outputCGImage.height)
        return NSImage(cgImage: outputCGImage, size: size)
        #endif
    }
    
    /// Apply adaptive thresholding to improve text contrast
    /// - Parameters:
    ///   - image: The image to process
    ///   - blockSize: Size of the pixel neighborhood for thresholding
    ///   - thresholdConstant: Constant subtracted from mean
    /// - Returns: Enhanced image or error
    static func adaptiveThreshold(image: ImageType, blockSize: Int = 11, thresholdConstant: Double = 2.0) -> EnhancementResult {
        // Convert to grayscale CIImage
        #if canImport(UIKit)
        guard let ciImage = CIImage(image: image) else {
            return .failure(error: EnhancementError.imageConversionFailed)
        }
        #else
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let ciImage = CIImage(cgImage: cgImage) else {
            return .failure(error: EnhancementError.imageConversionFailed)
        }
        #endif
        
        // Create grayscale filter
        let grayscaleFilter = CIFilter.colorMonochrome()
        grayscaleFilter.inputImage = ciImage
        grayscaleFilter.color = CIColor(red: 1, green: 1, blue: 1)
        grayscaleFilter.intensity = 1.0
        
        guard let grayscaleImage = grayscaleFilter.outputImage else {
            return .failure(error: EnhancementError.filterProcessingFailed)
        }
        
        // Apply thresholding using Core Image filters
        let context = CIContext(options: nil)
        
        // Blur the image (to calculate local means)
        let blurFilter = CIFilter.gaussianBlur()
        blurFilter.inputImage = grayscaleImage
        blurFilter.radius = Float(blockSize) / 2
        
        guard let blurredImage = blurFilter.outputImage else {
            return .failure(error: EnhancementError.filterProcessingFailed)
        }
        
        // Create a custom filter for thresholding
        let thresholdKernel = CIColorKernel(source:
            """
            kernel vec4 thresholdFilter(__sample image, __sample blurred, float c) {
                float value = image.r;
                float mean = blurred.r;
                return (value > mean - c) ? vec4(1.0, 1.0, 1.0, 1.0) : vec4(0.0, 0.0, 0.0, 1.0);
            }
            """
        )
        
        guard let thresholdKernel = thresholdKernel else {
            return .failure(error: EnhancementError.filterProcessingFailed)
        }
        
        let cValue = Float(thresholdConstant / 255.0)
        guard let thresholdImage = thresholdKernel.apply(
            extent: grayscaleImage.extent,
            arguments: [grayscaleImage, blurredImage, cValue]
        ) else {
            return .failure(error: EnhancementError.filterProcessingFailed)
        }
        
        // Convert to CGImage
        guard let outputCGImage = context.createCGImage(thresholdImage, from: thresholdImage.extent) else {
            return .failure(error: EnhancementError.outputCreationFailed)
        }
        
        // Convert to platform-specific image type
        #if canImport(UIKit)
        return .success(image: UIImage(cgImage: outputCGImage))
        #else
        let size = NSSize(width: outputCGImage.width, height: outputCGImage.height)
        return .success(image: NSImage(cgImage: outputCGImage, size: size))
        #endif
    }
    
    /// Detect and correct skew in ID images
    /// - Parameter image: The image to deskew
    /// - Returns: Deskewed image or error
    static func deskewImage(_ image: ImageType) -> EnhancementResult {
        // Convert to grayscale CIImage
        #if canImport(UIKit)
        guard let ciImage = CIImage(image: image) else {
            return .failure(error: EnhancementError.imageConversionFailed)
        }
        #else
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let ciImage = CIImage(cgImage: cgImage) else {
            return .failure(error: EnhancementError.imageConversionFailed)
        }
        #endif
        
        // Create context
        let context = CIContext(options: nil)
        
        // Apply grayscale filter
        let grayscaleFilter = CIFilter.colorMonochrome()
        grayscaleFilter.inputImage = ciImage
        grayscaleFilter.color = CIColor(red: 1, green: 1, blue: 1)
        grayscaleFilter.intensity = 1.0
        
        guard let grayscaleImage = grayscaleFilter.outputImage else {
            return .failure(error: EnhancementError.filterProcessingFailed)
        }
        
        // Create edge detection filter
        let edgeFilter = CIFilter.edges()
        edgeFilter.inputImage = grayscaleImage
        edgeFilter.intensity = 1.0
        
        guard let edgeImage = edgeFilter.outputImage else {
            return .failure(error: EnhancementError.filterProcessingFailed)
        }
        
        // Apply Hough transform to detect lines (not directly available in Core Image)
        // For this MVP, we'll use a simplified approach with affine transform
        
        // Assume a small skew angle for correction (±5 degrees max)
        let skewAngles: [CGFloat] = [-5.0, -4.0, -3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0, 5.0]
        var bestAngle: CGFloat = 0.0
        var maxVariance: CGFloat = 0.0
        
        // Test each angle
        for angle in skewAngles {
            // Create affine transform
            let rotateTransform = CGAffineTransform(rotationAngle: angle * CGFloat.pi / 180.0)
            let rotatedImage = edgeImage.transformed(by: rotateTransform)
            
            // Attempt to create CGImage
            guard let cgEdgeImage = context.createCGImage(rotatedImage, from: rotatedImage.extent) else {
                continue
            }
            
            // Calculate horizontal projection profile
            let variance = calculateHorizontalVariance(cgEdgeImage)
            
            // Keep track of angle that produces maximum variance (best horizontal alignment)
            if variance > maxVariance {
                maxVariance = variance
                bestAngle = angle
            }
        }
        
        // Apply correction with best angle
        let correctionTransform = CGAffineTransform(rotationAngle: -bestAngle * CGFloat.pi / 180.0)
        let correctedImage = ciImage.transformed(by: correctionTransform)
        
        // Create final output image
        guard let outputCGImage = context.createCGImage(correctedImage, from: correctedImage.extent) else {
            return .failure(error: EnhancementError.outputCreationFailed)
        }
        
        // Convert to platform-specific image type
        #if canImport(UIKit)
        return .success(image: UIImage(cgImage: outputCGImage))
        #else
        let size = NSSize(width: outputCGImage.width, height: outputCGImage.height)
        return .success(image: NSImage(cgImage: outputCGImage, size: size))
        #endif
    }
    
    /// Calculate horizontal projection profile variance
    /// - Parameter cgImage: CGImage to analyze
    /// - Returns: Variance value as measure of horizontal alignment
    private static func calculateHorizontalVariance(_ cgImage: CGImage) -> CGFloat {
        let width = cgImage.width
        let height = cgImage.height
        
        // Create a bitmap context to access pixel data
        let bytesPerRow = width * 4
        guard let data = calloc(height * bytesPerRow, 1) else {
            return 0.0
        }
        defer { free(data) }
        
        guard let context = CGContext(data: data,
                                     width: width,
                                     height: height,
                                     bitsPerComponent: 8,
                                     bytesPerRow: bytesPerRow,
                                     space: CGColorSpaceCreateDeviceRGB(),
                                     bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return 0.0
        }
        
        // Draw the image into the context
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Create histogram for horizontal projection
        var histogram = [CGFloat](repeating: 0, count: height)
        let buffer = data.assumingMemoryBound(to: UInt8.self)
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelOffset = y * bytesPerRow + x * 4
                // Average RGB components
                let value = (CGFloat(buffer[pixelOffset]) + 
                            CGFloat(buffer[pixelOffset + 1]) + 
                            CGFloat(buffer[pixelOffset + 2])) / 3.0
                histogram[y] += value
            }
        }
        
        // Calculate variance of the histogram
        let mean = histogram.reduce(0, +) / CGFloat(histogram.count)
        let variance = histogram.map { pow($0 - mean, 2) }.reduce(0, +) / CGFloat(histogram.count)
        
        return variance
    }
} 