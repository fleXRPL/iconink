import SwiftUI
import UIKit
import UniformTypeIdentifiers
import CoreData

struct DataManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.name, ascending: true)],
        animation: .default)
    private var clients: FetchedResults<Client>
    
    @AppStorage("encryptData") private var encryptData = false
    
    @State private var showingExportAlert = false
    @State private var showingImportPicker = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var exportSuccess = false
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var importedClientCount = 0
    @State private var showingImportSuccess = false
    
    var body: some View {
        Form {
            Section(header: Text("Export Data")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Export all clients and their associated consent forms")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if clients.isEmpty {
                        Text("No clients available to export")
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    } else {
                        Text("Available clients: \(clients.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    
                    Button {
                        exportData()
                    } label: {
                        if isExporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Export Data")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(clients.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.vertical, 8)
                    .disabled(clients.isEmpty || isExporting)
                }
            }
            
            Section(header: Text("Import Data")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Import previously exported client data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Importing will add new clients without affecting existing ones")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    
                    Toggle("Data is encrypted", isOn: $encryptData)
                        .padding(.vertical, 8)
                    
                    Button {
                        showingImportPicker = true
                    } label: {
                        if isImporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Import Data")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.vertical, 8)
                    .disabled(isImporting)
                }
            }
            
            Section(header: Text("Data Security")) {
                Toggle("Encrypt exported data", isOn: $encryptData)
                    .tint(.blue)
                
                Text("When enabled, exported data will be encrypted and can only be imported by this app with encryption enabled")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .navigationTitle("Data Management")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingExportAlert) {
            if exportSuccess, let url = exportURL {
                return Alert(
                    title: Text("Export Successful"),
                    message: Text("Client data has been exported successfully. Do you want to share the file?"),
                    primaryButton: .default(Text("Share")) {
                        shareExportedFile(url: url)
                    },
                    secondaryButton: .cancel(Text("Done"))
                )
            } else {
                return Alert(
                    title: Text("Export Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .alert("Import Successful", isPresented: $showingImportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Successfully imported \(importedClientCount) client(s).")
        }
        .alert("Import Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingImportPicker) {
            DocumentPickerView(
                contentTypes: [UTType.json],
                onDocumentsPicked: { urls in
                    if let url = urls.first {
                        importData(from: url)
                    }
                }
            )
        }
    }
    
    private func exportData() {
        guard !clients.isEmpty else { return }
        
        isExporting = true
        
        // Convert FetchedResults to array
        let clientsArray = Array(clients)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = ClientDataManager.exportClients(clientsArray, encryptData: encryptData)
            
            DispatchQueue.main.async {
                isExporting = false
                
                switch result {
                case .success(let url):
                    exportSuccess = true
                    exportURL = url
                    showingExportAlert = true
                case .failure(let error):
                    exportSuccess = false
                    errorMessage = "Failed to export data: \(error)"
                    showingExportAlert = true
                }
            }
        }
    }
    
    private func importData(from url: URL) {
        isImporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = ClientDataManager.importClients(from: url, context: viewContext, isEncrypted: encryptData)
            
            DispatchQueue.main.async {
                isImporting = false
                
                switch result {
                case .success(let clients):
                    importedClientCount = clients.count
                    showingImportSuccess = true
                case .failure(let error):
                    switch error {
                    case .decodingFailed:
                        errorMessage = "Could not decrypt the data. Make sure the encryption setting matches how the data was exported."
                    case .invalidData:
                        errorMessage = "The file contains invalid data."
                    case .fileReadFailed:
                        errorMessage = "Could not read the file."
                    default:
                        errorMessage = "Import failed: \(error)"
                    }
                    showingErrorAlert = true
                }
            }
        }
    }
    
    private func shareExportedFile(url: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        ClientDataManager.shareExportedFile(fileURL: url, presenter: rootViewController)
    }
}

// Document picker for importing files
struct DocumentPickerView: UIViewControllerRepresentable {
    let contentTypes: [UTType]
    let onDocumentsPicked: ([URL]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.onDocumentsPicked(urls)
        }
    }
}

#Preview {
    NavigationStack {
        DataManagementView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 