import SwiftUI
import PencilKit

struct SignatureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var canvasView = PKCanvasView()
    @State private var signatureImage: UIImage?
    @State private var isShowingPreview = false
    @State private var signatureType: Int16 = 0
    @State private var showingClearConfirmation = false
    @State private var showingDiscardConfirmation = false
    
    var consentForm: ConsentForm?
    var onSignatureSaved: ((UIImage) -> Void)?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Signature type selector
                Picker("Signature Type", selection: $signatureType) {
                    Text("Client").tag(Int16(0))
                    Text("Artist").tag(Int16(1))
                    Text("Parent/Guardian").tag(Int16(2))
                    Text("Witness").tag(Int16(3))
                }
                .pickerStyle(.segmented)
                .padding()
                
                Divider()
                
                if isShowingPreview, let image = signatureImage {
                    // Signature preview
                    VStack {
                        Text("Signature Preview")
                            .font(.headline)
                            .padding(.top)
                        
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .padding()
                        
                        Text("Is this signature acceptable?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            Button {
                                isShowingPreview = false
                            } label: {
                                Text("Redraw")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray5))
                                    .foregroundColor(.primary)
                                    .cornerRadius(10)
                            }
                            
                            Button {
                                saveSignature()
                            } label: {
                                Text("Accept")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                    }
                } else {
                    // Signature canvas
                    VStack {
                        Text("Please sign below")
                            .font(.headline)
                            .padding(.top)
                        
                        ZStack {
                            // Canvas background
                            Rectangle()
                                .fill(Color(.systemGray6))
                            
                            // Signature line
                            VStack {
                                Spacer()
                                Rectangle()
                                    .fill(Color.gray.opacity(0.5))
                                    .frame(height: 1)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 40)
                            }
                            
                            // Canvas view
                            SignatureCanvasView(canvasView: $canvasView)
                        }
                        .frame(maxHeight: .infinity)
                        
                        // Canvas controls
                        HStack {
                            Button {
                                showingClearConfirmation = true
                            } label: {
                                Label("Clear", systemImage: "trash")
                                    .foregroundColor(.red)
                            }
                            .disabled(canvasView.drawing.strokes.isEmpty)
                            
                            Spacer()
                            
                            Button {
                                captureSignature()
                            } label: {
                                Text("Done")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 10)
                                    .background(canvasView.drawing.strokes.isEmpty ? Color.gray : Color.accentColor)
                                    .cornerRadius(10)
                            }
                            .disabled(canvasView.drawing.strokes.isEmpty)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Capture Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if !canvasView.drawing.strokes.isEmpty && !isShowingPreview {
                            showingDiscardConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .alert("Clear Signature", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearSignature()
                }
            } message: {
                Text("Are you sure you want to clear the signature?")
            }
            .alert("Discard Signature", isPresented: $showingDiscardConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to discard this signature?")
            }
        }
    }
    
    // Capture the signature from the canvas
    private func captureSignature() {
        // Create a UIImage from the canvas
        let renderer = UIGraphicsImageRenderer(bounds: canvasView.bounds)
        let image = renderer.image { _ in
            canvasView.drawHierarchy(in: canvasView.bounds, afterScreenUpdates: true)
        }
        
        // Crop the image to remove excess whitespace
        if let croppedImage = cropSignature(image) {
            signatureImage = croppedImage
            isShowingPreview = true
        } else {
            signatureImage = image
            isShowingPreview = true
        }
    }
    
    // Crop the signature image to remove excess whitespace
    private func cropSignature(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        // Convert to grayscale to simplify processing
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        guard let context = CGContext(
            data: nil,
            width: cgImage.width,
            height: cgImage.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }
        
        let rect = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        context.draw(cgImage, in: rect)
        
        guard let grayscaleImage = context.makeImage() else { return nil }
        
        // Find the bounds of the signature
        var minX = cgImage.width
        var minY = cgImage.height
        var maxX: Int = 0
        var maxY: Int = 0
        
        guard let pixelData = grayscaleImage.dataProvider?.data,
              let data = CFDataGetBytePtr(pixelData) else { return nil }
        
        for y in 0..<grayscaleImage.height {
            for x in 0..<grayscaleImage.width {
                let pixelIndex = y * grayscaleImage.bytesPerRow + x
                if data[pixelIndex] < 128 { // Non-white pixel
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }
        
        // Add padding
        let padding = 20
        minX = max(0, minX - padding)
        minY = max(0, minY - padding)
        maxX = min(cgImage.width - 1, maxX + padding)
        maxY = min(cgImage.height - 1, maxY + padding)
        
        // Check if we found a signature
        if maxX <= minX || maxY <= minY {
            return image // Return original if no signature found
        }
        
        // Create a cropped image
        let width = maxX - minX
        let height = maxY - minY
        if let croppedCGImage = cgImage.cropping(to: CGRect(x: minX, y: minY, width: width, height: height)) {
            return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
        }
        
        return image
    }
    
    // Clear the signature canvas
    private func clearSignature() {
        canvasView.drawing = PKDrawing()
    }
    
    // Save the signature
    private func saveSignature() {
        guard let image = signatureImage else { return }
        
        // If a consent form is provided, save the signature to the form
        if let consentForm = consentForm {
            _ = Signature.createSignature(
                in: viewContext,
                signatureImage: image,
                signatureType: signatureType,
                consentForm: consentForm
            )
            
            do {
                try viewContext.save()
            } catch {
                print("Error saving signature: \(error.localizedDescription)")
            }
        }
        
        // Call the completion handler if provided
        onSignatureSaved?(image)
        
        dismiss()
    }
}

// Canvas view wrapper for PencilKit
struct SignatureCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    
    func makeUIView(_ _: UIViewType) -> UIViewType {
        let canvasView = PKCanvasView()
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 1)
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.maximumZoomScale = 1
        canvasView.minimumZoomScale = 1
        canvasView.delegate = context.coordinator
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // No updates needed
    }
}

#Preview {
    SignatureView()
} 
