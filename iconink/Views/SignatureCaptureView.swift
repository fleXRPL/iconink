import SwiftUI
import PencilKit

struct SignatureCaptureView: View {
    @Binding var signatureData: Data?
    @Environment(\.dismiss) private var dismiss
    @State private var canvasView = PKCanvasView()
    
    var body: some View {
        NavigationStack {
            VStack {
                SignatureCanvas(canvasView: $canvasView)
                    .frame(maxHeight: .infinity)
                
                Button("Clear") {
                    canvasView.drawing = PKDrawing()
                }
                .padding()
            }
            .navigationTitle("Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveSignature()
                    }
                }
            }
        }
    }
    
    private func saveSignature() {
        let image = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
        signatureData = image.pngData()
        dismiss()
    }
}

struct SignatureCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 1)
        canvasView.backgroundColor = .clear
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
