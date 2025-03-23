import SwiftUI
import AVFoundation
import UIKit
import CoreData

struct CameraView: View {
    let isCapturingFront: Bool
    let client: NSManagedObject
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @StateObject private var camera = CameraController()
    @State private var showingPreview = false
    @State private var capturedImage: UIImage?
    @State private var showingPermissionAlert = false
    
    static func preview() -> CameraView {
        let context = PersistenceController.preview.container.viewContext
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "Client", in: context) else {
            fatalError("Failed to get entity description for Client")
        }
        let client = NSManagedObject(entity: entityDescription, insertInto: context)
        // Set basic properties for preview
        client.setValue(UUID(), forKey: "id")
        client.setValue("Test Client", forKey: "name")
        return CameraView(isCapturingFront: true, client: client)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Camera preview
                if camera.isReady {
                    CameraPreviewView(session: camera.session)
                        .ignoresSafeArea()
                        .overlay {
                            // ID card frame guide
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: UIScreen.main.bounds.width * 0.8,
                                       height: UIScreen.main.bounds.width * 0.5)
                                .overlay {
                                    Rectangle()
                                        .stroke(Color.white, style: StrokeStyle(lineWidth: 1, dash: [5]))
                                }
                        }
                } else {
                    Color.black
                        .ignoresSafeArea()
                        .overlay {
                            if !camera.isAuthorized {
                                VStack(spacing: 20) {
                                    Image(systemName: "camera.slash.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(.white)
                                    Text("Camera Access Required")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    Text("Please enable camera access in Settings to capture ID photos.")
                                        .font(.body)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                    Button("Open Settings") {
                                        if let url = URL(string: UIApplication.openSettingsURLString) {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.white)
                                }
                            } else {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                }
                
                // Capture interface
                VStack {
                    // Top bar with title
                    Text(isCapturingFront ? "Front of ID" : "Back of ID")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    Spacer()
                    
                    // Instructions and capture button
                    VStack(spacing: 20) {
                        Text("Position ID within the frame")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text("Ensure all text is clearly visible")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button {
                            camera.capturePhoto { image in
                                capturedImage = image
                                showingPreview = true
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 72, height: 72)
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                                    .frame(width: 80, height: 80)
                            }
                        }
                        .disabled(!camera.isReady)
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingPreview) {
            if let image = capturedImage {
                NavigationStack {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .overlay {
                                // Preview overlay with tips
                                VStack {
                                    Spacer()
                                    HStack {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Label("Check if text is readable", systemImage: "text.magnifyingglass")
                                            Label("No glare or shadows", systemImage: "sun.max")
                                            Label("Entire ID is visible", systemImage: "checkmark.rectangle")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(.black.opacity(0.6))
                                        .cornerRadius(10)
                                        Spacer()
                                    }
                                    .padding()
                                }
                            }
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Retake") {
                                showingPreview = false
                            }
                            .foregroundColor(.white)
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Use Photo") {
                                savePhoto(image)
                                dismiss()
                            }
                            .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .onAppear {
            camera.checkPermissions()
        }
    }
    
    private func savePhoto(_ image: UIImage) {
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            if isCapturingFront {
                client.setValue(imageData, forKey: "frontIdPhoto")
            } else {
                client.setValue(imageData, forKey: "backIdPhoto")
            }
            
            do {
                try viewContext.save()
            } catch {
                print("Error saving photo: \(error)")
            }
        }
    }
}

// Camera preview using UIViewRepresentable
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}

#Preview {
    CameraView.preview()
}
