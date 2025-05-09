import SwiftUI
import PencilKit
import CoreData

struct SignatureCaptureView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = SignatureCaptureViewModel()
    
    let client: Client?
    let consentForm: ConsentForm?
    var onSignatureCapture: ((Signature) -> Void)?
    
    @State private var canvasView = PKCanvasView()
    @State private var showingPreview = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Signature canvas
                SignatureCanvasView(canvasView: $canvasView)
                    .frame(height: 200)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding()
                
                // Instructions
                Text("Please sign above")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Preview if signature exists
                if let previewImage = viewModel.previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .padding()
                }
                
                HStack(spacing: 20) {
                    // Clear button
                    Button(action: clearSignature) {
                        Label("Clear", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(10)
                    }
                    
                    // Save button
                    Button(action: saveSignature) {
                        Label("Save", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
            .navigationBarTitle("Capture Signature", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button(action: {
                    showingPreview = true
                }) {
                    Image(systemName: "eye")
                }
            )
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingPreview) {
                SignaturePreviewView(
                    drawing: canvasView.drawing,
                    onDismiss: { showingPreview = false }
                )
            }
        }
    }
    
    private func clearSignature() {
        canvasView.drawing = PKDrawing()
        viewModel.previewImage = nil
    }
    
    private func saveSignature() {
        let drawing = canvasView.drawing
        
        guard !drawing.bounds.isEmpty else {
            showAlert(title: "Empty Signature", message: "Please provide a signature before saving.")
            return
        }
        
        do {
            let signature = try viewModel.saveSignature(
                drawing: drawing,
                in: viewContext,
                client: client,
                consentForm: consentForm
            )
            
            onSignatureCapture?(signature)
            dismiss()
        } catch {
            showAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

struct SignatureCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 1)
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}

struct SignaturePreviewView: View {
    let drawing: PKDrawing
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                Image(uiImage: drawing.image(from: drawing.bounds, scale: UIScreen.main.scale))
                    .resizable()
                    .scaledToFit()
                    .padding()
                
                Text("Signature Preview")
                    .font(.headline)
                    .padding()
            }
            .navigationBarTitle("Preview", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                onDismiss()
            })
        }
    }
}

class SignatureCaptureViewModel: ObservableObject {
    @Published var previewImage: UIImage?
    
    func saveSignature(
        drawing: PKDrawing,
        in context: NSManagedObjectContext,
        client: Client?,
        consentForm: ConsentForm?
    ) throws -> Signature {
        guard let signatureData = try? drawing.dataRepresentation() else {
            throw SignatureError.invalidData
        }
        
        let signature = Signature.create(
            in: context,
            signatureData: signatureData,
            signedBy: client?.name ?? "Unknown",
            client: client,
            consentForm: consentForm
        )
        
        let validationResult = signature.validate()
        if !validationResult.isValid {
            throw validationResult.error ?? SignatureError.validationFailed("Unknown validation error")
        }
        
        try context.save()
        return signature
    }
}

#Preview {
    SignatureCaptureView(client: nil, consentForm: nil)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
