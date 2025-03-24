import SwiftUI
import Vision
import VisionKit

struct IDScannerView: View {
    @Environment(.managedObjectContext) private var viewContext
    @Environment(.dismiss) private var dismiss
    
    @State private var showingScanner = false
    @State private var scannedImage: UIImage?
    @State private var extractedInfo: [String: String] = [:]
    @State private var isScanning = false
    @State private var scanError: String?
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var client: Client?
    var onClientInfoExtracted: (([String: String]) -> Void)?
    
    var body: some View {
        NavigationStack {
            VStack {
                if let scannedImage = scannedImage {
                    // Display the scanned image
                    Image(uiImage: scannedImage)
                        .resizable()
                        .scaledToFit()
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding()
                    
                    // Display extracted information
                    if !extractedInfo.isEmpty {
                        List {
                            Section("Extracted Information") {
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
                            .foregroundColor(.gray)
                        
                        Text("Scan an ID document to extract information")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Text("Position the ID document within the scanner frame")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
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
            }
            .navigationTitle("ID Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingScanner = true
                    }) {
                        Image(systemName: "camera")
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                CameraView(isCapturingFront: true) { image in
                    self.scannedImage = image
                    self.scanImage(image)
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func scanImage(_ image: UIImage) {
        isScanning = true
        extractedInfo = [:]
        scanError = nil
        
        IDScanner.scanID(from: image) { result in
            DispatchQueue.main.async {
                isScanning = false
                
                switch result {
                case .success(let info):
                    if !info.isEmpty {
                        extractedInfo = info
                    } else {
                        alertTitle = "No Information Found"
                        alertMessage = "Could not extract any information from this document. Please try again with a clearer image."
                        showingAlert = true
                    }
                    
                case .failure(let error):
                    scanError = error
                    alertTitle = "Scanning Failed"
                    alertMessage = error
                    showingAlert = true
                }
            }
        }
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
        
        // Save the context
        do {
            try viewContext.save()
            alertTitle = "Success"
            alertMessage = "Client information has been updated."
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

#Preview {
    IDScannerView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}