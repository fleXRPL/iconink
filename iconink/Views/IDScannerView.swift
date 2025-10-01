import SwiftUI
import Vision
import VisionKit
import UIKit
import CoreData

/// Secondary views to reduce the main view's complexity
struct ScanStatusOverlay: View {
    let scanError: String?
    let extractedInfo: [String: String]
    let onTryAgain: () -> Void
    
    var body: some View {
        if scanError != nil {
            VStack {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("Scanning Failed")
                        .font(.headline)
                        .foregroundColor(.red)
                }
                .padding(8)
                .background(Color.white.opacity(0.9))
                .cornerRadius(8)
                .padding(.top, 24)
                
                Spacer()
                
                Button(action: onTryAgain) {
                    Text("Try Again")
                        .fontWeight(.medium)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.bottom, 24)
            }
        } else if !extractedInfo.isEmpty {
            VStack {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("Information Extracted")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .padding(8)
                .background(Color.white.opacity(0.9))
                .cornerRadius(8)
                .padding(.top, 24)
                
                Spacer()
            }
        }
    }
}

/// Empty state view shown when no image is scanned
struct EmptyScannerView: View {
    let onShowTips: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.blue.opacity(0.8))
            
            Text("Scan an ID document to extract information")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
            
            Text("Position the ID document within the scanner frame")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onShowTips) {
                Label("Scanning Tips", systemImage: "lightbulb")
                    .font(.subheadline)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.yellow.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(20)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
}

/// View showing extracted information in a list
struct ExtractedInfoListView: View {
    let extractedInfo: [String: String]
    let onUseInfo: () -> Void
    
    var body: some View {
        VStack {
            List {
                Section(header: Text("Extracted Information")) {
                    ForEach(extractedInfo.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack {
                            Text(key.capitalized)
                                .fontWeight(.medium)
                            Spacer()
                            Text(value)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .frame(height: 200)
            
            // Use extracted info button
            Button(action: onUseInfo) {
                Text("Use This Information")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
        }
    }
}

struct IDScannerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingScanner = false
    @State private var scannedImage: UIImage?
    @State private var extractedInfo: [String: String] = [:]
    @State private var isScanning = false
    @State private var scanError: String?
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingTips = false
    @State private var scanAttempts = 0
    @State private var usedFallbackMethod = false
    
    let client: Client?
    let onClientInfoExtracted: (([String: String]) -> Void)?
    
    init(client: Client? = nil, onClientInfoExtracted: (([String: String]) -> Void)? = nil) {
        self.client = client
        self.onClientInfoExtracted = onClientInfoExtracted
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if let scannedImage = scannedImage {
                    // Display the scanned image with status indicator
                    Image(uiImage: scannedImage)
                        .resizable()
                        .scaledToFit()
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding()
                        .overlay(
                            ScanStatusOverlay(
                                scanError: scanError,
                                extractedInfo: extractedInfo,
                                onTryAgain: { showingScanner = true }
                            )
                        )
                    
                    // Display extracted information if available
                    if !extractedInfo.isEmpty {
                        ExtractedInfoListView(
                            extractedInfo: extractedInfo,
                            onUseInfo: useExtractedInfo
                        )
                    }
                } else {
                    // Placeholder when no image is scanned
                    EmptyScannerView(onShowTips: { showingTips = true })
                }
                
                // Loading indicator during scanning
                if isScanning {
                    ProgressView("Analyzing document...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                }
                
                // Scan button
                if !isScanning {
                    Button(action: {
                        showingScanner = true
                    }) {
                        HStack {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 18))
                            Text(scannedImage == nil ? "Scan ID Document" : "Scan Again")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationBarTitle("ID Scanner", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: scannedImage != nil ? Button(action: {
                    // Clear scanned data
                    scannedImage = nil
                    extractedInfo = [:]
                    scanError = nil
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                } : nil
            )
            .sheet(isPresented: $showingScanner) {
                CameraView(isCapturingFront: true, onImageCaptured: { image in
                    self.scannedImage = image
                    self.scanImage(image)
                    self.scanAttempts += 1
                })
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingTips) {
                TipsView(isPresented: $showingTips)
            }
        }
    }
    
    /// Processes the scanned image using Vision framework
    /// - Parameter image: The scanned image to process
    private func scanImage(_ image: UIImage) {
        isScanning = true
        scanError = nil
        
        // Create a new image-request handler
        guard let cgImage = image.cgImage else {
            handleScanError("Invalid image format")
            return
        }
        
        // Create a new request to recognize text
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                self.handleScanError("Text recognition failed: \(error.localizedDescription)")
                return
            }
            
            // Process the recognized text
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                self.handleScanError("No text found in image")
                return
            }
            
            // Extract text from observations
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            // Parse the extracted text
            let extractedInfo = IDTextParser.parseIDInformation(from: recognizedStrings)
            
            // Validate the extracted information
            if IDTextParser.validateExtractedInfo(extractedInfo) {
                self.handleSuccessfulScan(image, extractedInfo)
            } else {
                self.handleScanError("Could not extract required information")
            }
        }
        
        // Configure the request
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.customWords = ["ID", "LICENSE", "PASSPORT", "DRIVER", "STATE"]
        
        // Perform the text-recognition request
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            handleScanError("Failed to process image: \(error.localizedDescription)")
        }
    }
    
    /// Handles a successful scan
    /// - Parameters:
    ///   - image: The scanned image
    ///   - info: The extracted information
    private func handleSuccessfulScan(_ image: UIImage, _ info: [String: String]) {
        DispatchQueue.main.async {
            self.extractedInfo = info
            self.isScanning = false
            
            // Create IDScan entity
            let scan = IDScan.create(
                in: self.viewContext,
                imageData: image.jpegData(compressionQuality: 0.8),
                extractedInfo: info,
                client: self.client
            )
            
            // Save to CoreData
            do {
                try self.viewContext.save()
            } catch {
                self.handleScanError("Failed to save scan: \(error.localizedDescription)")
            }
        }
    }
    
    /// Handles scan errors
    /// - Parameter message: The error message
    private func handleScanError(_ message: String) {
        DispatchQueue.main.async {
            self.scanError = message
            self.isScanning = false
            self.alertTitle = "Scanning Error"
            self.alertMessage = message
            self.showingAlert = true
        }
    }
    
    /// Uses the extracted information
    private func useExtractedInfo() {
        if let onClientInfoExtracted = onClientInfoExtracted {
            onClientInfoExtracted(extractedInfo)
            dismiss()
        }
    }
}

// Simple tips view for ID scanning
struct TipsView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Getting a Clear Scan")) {
                    tipRow(icon: "sun.max.fill", title: "Good Lighting", description: "Ensure the ID is well-lit, avoiding glare or shadows.")
                    tipRow(icon: "hand.raised.fill", title: "Hold Steady", description: "Keep your hand steady to avoid blur.")
                    tipRow(icon: "camera.viewfinder", title: "Frame the ID", description: "Make sure the entire ID is visible in the frame.")
                    tipRow(icon: "rectangle.fill", title: "Flat Surface", description: "Place the ID on a flat contrasting background.")
                }
                
                Section(header: Text("If You're Having Trouble")) {
                    tipRow(icon: "arrow.counterclockwise", 
                           title: "Try Different Angles", 
                           description: "Slightly adjust your angle if information isn't being detected.")
                    tipRow(icon: "photo.fill", 
                           title: "Avoid Glare", 
                           description: "Tilt the camera if there's glare from the ID's surface.")
                    tipRow(icon: "doc.text.magnifyingglass", 
                           title: "Readable Text", 
                           description: "Ensure text on the ID is clearly visible and not faded.")
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle("ID Scanning Tips", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
    
    private func tipRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    IDScannerView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
