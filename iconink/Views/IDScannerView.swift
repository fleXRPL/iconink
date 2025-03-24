import SwiftUI
import Vision
import VisionKit
import UIKit
import CoreData

struct IDScannerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingScanner = false
    @State private var scannedImage: UIImage?
    @State private var extractedInfo: [String: String] = [:]
    @State private var isScanning = false
    @State private var scanError: String?
    @State private var scanErrorType: IDScanErrorType?
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingTips = false
    @State private var scanAttempts = 0
    
    var client: Client?
    var onClientInfoExtracted: (([String: String]) -> Void)?
    
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
                        .overlay(scanStatusOverlay)
                    
                    // Display extracted information
                    if !extractedInfo.isEmpty {
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
                        Button(action: useExtractedInfo) {
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
                } else {
                    // Placeholder when no image is scanned
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
                        
                        Button(action: {
                            showingTips = true
                        }) {
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
                    scanErrorType = nil
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                } : nil
            )
            .sheet(isPresented: $showingScanner) {
                CameraView(isCapturingFront: true) { image in
                    self.scannedImage = image
                    self.scanImage(image)
                    self.scanAttempts += 1
                }
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
    
    @ViewBuilder
    private var scanStatusOverlay: some View {
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
                
                Button(action: {
                    showingScanner = true
                }) {
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
    
    private func scanImage(_ image: UIImage) {
        isScanning = true
        extractedInfo = [:]
        scanError = nil
        scanErrorType = nil
        
        IDScanner.scanID(from: image) { result in
            DispatchQueue.main.async {
                isScanning = false
                
                switch result {
                case .success(let info):
                    if !info.isEmpty {
                        extractedInfo = info
                        
                        // Check if we have all important fields
                        let missingFields = checkMissingImportantFields(info)
                        if !missingFields.isEmpty {
                            alertTitle = "Missing Information"
                            let fieldsText = missingFields.joined(separator: ", ")
                            alertMessage = "The following fields could not be detected: \(fieldsText). "
                                + "You may want to try scanning again or fill in this information manually."
                            showingAlert = true
                        }
                    } else {
                        scanError = "No information could be extracted from this document."
                        scanErrorType = .noTextFound
                        
                        if scanAttempts > 1 {
                            showingTips = true
                        }
                    }
                    
                case .failure(let error, let errorType):
                    scanError = error
                    scanErrorType = errorType
                    alertTitle = "Scanning Issue"
                    alertMessage = error
                    showingAlert = true
                    
                    if scanAttempts > 1 {
                        showingTips = true
                    }
                }
            }
        }
    }
    
    private func checkMissingImportantFields(_ info: [String: String]) -> [String] {
        var missingFields: [String] = []
        
        if info["name"] == nil || info["name"]?.isEmpty == true {
            missingFields.append("Name")
        }
        
        if info["idNumber"] == nil || info["idNumber"]?.isEmpty == true {
            missingFields.append("ID Number")
        }
        
        if info["dob"] == nil || info["dob"]?.isEmpty == true {
            missingFields.append("Date of Birth")
        }
        
        return missingFields
    }
    
    private func useExtractedInfo() {
        // If callback is provided, use it
        if let onClientInfoExtracted = onClientInfoExtracted {
            onClientInfoExtracted(extractedInfo)
            dismiss()
            return
        }
        
        // Otherwise update client if provided
        guard let client = client else {
            dismiss()
            return
        }
        
        // Update client with extracted information
        if let name = extractedInfo["name"] {
            client.name = name
        }
        
        if let email = extractedInfo["email"] {
            client.email = email
        }
        
        if let phone = extractedInfo["phone"] {
            client.phone = phone
        }
        
        if let address = extractedInfo["address"] {
            client.address = address
        }
        
        if let idNumber = extractedInfo["idNumber"] {
            client.idNumber = idNumber
        }
        
        // Save the context
        do {
            try viewContext.save()
            alertTitle = "Success"
            alertMessage = "Client information has been updated successfully."
            showingAlert = true
            
            // Dismiss after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to save client information: \(error.localizedDescription)"
            showingAlert = true
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
