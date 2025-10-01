import SwiftUI
import CoreData

struct SignatureView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let client: Client
    @State private var showingSignatureCapture = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let signatureImage = client.signatureImage {
                    // Show existing signature
                    Image(uiImage: signatureImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    
                    Button("Update Signature") {
                        showingSignatureCapture = true
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    // No signature yet
                    VStack(spacing: 20) {
                        Image(systemName: "signature")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No signature captured")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Button("Capture Signature") {
                            showingSignatureCapture = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingSignatureCapture) {
                SignatureCaptureView(client: client)
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let client = Client(context: context)
    client.name = "John Doe"
    
    return SignatureView(client: client)
        .environment(\.managedObjectContext, context)
}
