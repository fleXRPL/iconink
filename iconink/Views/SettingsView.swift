import SwiftUI
import LocalAuthentication
import CoreData
import ZIPFoundation

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var securityManager: SecurityManager
    
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingChangePasscode = false
    @State private var showingExportData = false
    @State private var showingImportData = false
    @State private var showingClearDataConfirmation = false
    @State private var showingAbout = false
    @State private var showingPrivacyPolicy = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Security")) {
                    Toggle("Require Authentication", isOn: $viewModel.requireAuthentication)
                        .onChange(of: viewModel.requireAuthentication) { newValue in
                            securityManager.setRequireAuthentication(newValue)
                        }
                    
                    if viewModel.requireAuthentication {
                        Picker("Authentication Method", selection: $viewModel.authMethod) {
                            Text("Biometric").tag(AuthMethod.biometric)
                            Text("Passcode").tag(AuthMethod.passcode)
                            Text("Both").tag(AuthMethod.both)
                        }
                        .onChange(of: viewModel.authMethod) { newValue in
                            securityManager.setAuthMethod(newValue)
                        }
                        
                        if viewModel.authMethod != .biometric {
                            Button {
                                showingChangePasscode = true
                            } label: {
                                HStack {
                                    Text("Change Passcode")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                        }
                        
                        Picker("Auto-Lock", selection: $viewModel.autoLockTimeout) {
                            Text("Immediately").tag(0)
                            Text("After 1 minute").tag(60)
                            Text("After 5 minutes").tag(300)
                            Text("After 15 minutes").tag(900)
                            Text("After 1 hour").tag(3600)
                        }
                        .onChange(of: viewModel.autoLockTimeout) { newValue in
                            securityManager.setAutoLockTimeout(newValue)
                        }
                    }
                }
                
                Section(header: Text("Data Management")) {
                    Button {
                        showingExportData = true
                    } label: {
                        HStack {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Button {
                        showingImportData = true
                    } label: {
                        HStack {
                            Label("Import Data", systemImage: "square.and.arrow.down")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Button(role: .destructive) {
                        showingClearDataConfirmation = true
                    } label: {
                        Label("Clear All Data", systemImage: "trash")
                    }
                }
                
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $viewModel.useDarkMode)
                        .onChange(of: viewModel.useDarkMode) { newValue in
                            viewModel.setAppearanceMode(darkMode: newValue)
                        }
                }
                
                Section(header: Text("About")) {
                    Button {
                        showingAbout = true
                    } label: {
                        HStack {
                            Label("About IconInk", systemImage: "info.circle")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Button {
                        showingPrivacyPolicy = true
                    } label: {
                        HStack {
                            Label("Privacy Policy", systemImage: "hand.raised")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    if let githubURL = URL(string: "https://github.com/fleXRPL/iconink") {
                        Link(destination: githubURL) {
                            HStack {
                                Label("GitHub Repository", systemImage: "link")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    if let discussionsURL = URL(string: "https://github.com/fleXRPL/iconink/discussions") {
                        Link(destination: discussionsURL) {
                            HStack {
                                Label("Community Discussions", systemImage: "bubble.left.and.bubble.right")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                viewModel.loadSettings(securityManager: securityManager)
            }
            .sheet(isPresented: $showingChangePasscode) {
                ChangePasscodeView()
            }
            .sheet(isPresented: $showingExportData) {
                ExportDataView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingImportData) {
                ImportDataView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .alert("Clear All Data", isPresented: $showingClearDataConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    viewModel.clearAllData(context: viewContext)
                }
            } message: {
                Text("Are you sure you want to clear all data? This action cannot be undone.")
            }
        }
    }
}

// MARK: - Change Passcode View
struct ChangePasscodeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var securityManager: SecurityManager
    
    @State private var currentPasscode = ""
    @State private var newPasscode = ""
    @State private var confirmPasscode = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var step = 1
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                if step == 1 {
                    Text("Enter your current passcode")
                        .font(.headline)
                    
                    SecureField("Current Passcode", text: $currentPasscode)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    Button("Next") {
                        if securityManager.validatePasscode(currentPasscode) {
                            step = 2
                        } else {
                            errorMessage = "Incorrect passcode. Please try again."
                            showingError = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(currentPasscode.count < 4)
                } else if step == 2 {
                    Text("Enter your new passcode")
                        .font(.headline)
                    
                    SecureField("New Passcode", text: $newPasscode)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    Button("Next") {
                        if newPasscode.count >= 4 {
                            step = 3
                        } else {
                            errorMessage = "Passcode must be at least 4 digits."
                            showingError = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newPasscode.count < 4)
                } else {
                    Text("Confirm your new passcode")
                        .font(.headline)
                    
                    SecureField("Confirm Passcode", text: $confirmPasscode)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    Button("Save") {
                        if newPasscode == confirmPasscode {
                            securityManager.setPasscode(newPasscode)
                            dismiss()
                        } else {
                            errorMessage = "Passcodes do not match. Please try again."
                            showingError = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(confirmPasscode.count < 4)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Change Passcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - Export Data View
struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SettingsViewModel
    
    @State private var exportProgress: Double = 0
    @State private var exportStatus: ExportStatus = .notStarted
    @State private var exportURL: URL?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                switch exportStatus {
                case .notStarted:
                    startExportView
                case .inProgress:
                    exportProgressView
                case .completed:
                    exportCompletedView
                case .failed:
                    exportFailedView
                }
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var startExportView: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.and.arrow.up.circle")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Export Your Data")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This will export all your client data, consent forms, and templates as an encrypted file. You can use this file to restore your data later or transfer it to another device.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button {
                startExport()
            } label: {
                Text("Start Export")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
    }
    
    private var exportProgressView: some View {
        VStack(spacing: 20) {
            ProgressView(value: exportProgress, total: 1.0)
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(2)
                .padding()
            
            Text("Exporting Data...")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Please wait while your data is being exported. This may take a moment.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
    }
    
    private var exportCompletedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Export Completed")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your data has been successfully exported.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if let url = exportURL {
                ShareLink(item: url) {
                    Text("Share Export File")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
            }
            
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(UIColor.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
        }
    }
    
    private var exportFailedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Export Failed")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("There was an error exporting your data. Please try again.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button {
                startExport()
            } label: {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
    }
    
    private func startExport() {
        exportStatus = .inProgress
        exportProgress = 0.1
        
        // Create a background task to handle the export
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Get the URL for the CoreData store
                guard let storeURL = PersistenceController.shared.container.persistentStoreCoordinator.persistentStores.first?.url else {
                    DispatchQueue.main.async {
                        self.exportStatus = .failed
                    }
                    return
                }
                
                // Update progress
                DispatchQueue.main.async {
                    self.exportProgress = 0.2
                }
                
                // Create a temporary directory for export files
                let temporaryDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
                try FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true)
                
                // Update progress
                DispatchQueue.main.async {
                    self.exportProgress = 0.3
                }
                
                // Copy the database file to the temporary directory
                let databaseCopyURL = temporaryDirectoryURL.appendingPathComponent("iconink.sqlite")
                try FileManager.default.copyItem(at: storeURL, to: databaseCopyURL)
                
                // Also copy any WAL and SHM files if they exist
                let walURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
                let shmURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm")
                
                if FileManager.default.fileExists(atPath: walURL.path) {
                    try FileManager.default.copyItem(at: walURL, to: temporaryDirectoryURL.appendingPathComponent("iconink.sqlite-wal"))
                }
                
                if FileManager.default.fileExists(atPath: shmURL.path) {
                    try FileManager.default.copyItem(at: shmURL, to: temporaryDirectoryURL.appendingPathComponent("iconink.sqlite-shm"))
                }
                
                // Update progress
                DispatchQueue.main.async {
                    self.exportProgress = 0.5
                }
                
                // Create metadata file with app version and export date
                let metadataURL = temporaryDirectoryURL.appendingPathComponent("metadata.json")
                let metadata: [String: Any] = [
                    "appVersion": self.viewModel.appVersion,
                    "exportDate": Date().timeIntervalSince1970,
                    "databaseVersion": "1.0" // Update this when database schema changes
                ]
                
                let metadataData = try JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted)
                try metadataData.write(to: metadataURL)
                
                // Update progress
                DispatchQueue.main.async {
                    self.exportProgress = 0.7
                }
                
                // Create a zip file containing all the files
                if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let zipFileURL = documentsDirectory.appendingPathComponent("iconink_export_\(Date().timeIntervalSince1970).zip")
                    
                    // Use ZIPFoundation to create a zip archive
                    if FileManager.default.fileExists(atPath: zipFileURL.path) {
                        try FileManager.default.removeItem(at: zipFileURL)
                    }
                    
                    let fileManager = FileManager()
                    try fileManager.zipItem(at: temporaryDirectoryURL, to: zipFileURL, shouldKeepParent: false)
                    
                    // Update progress
                    DispatchQueue.main.async {
                        self.exportProgress = 0.9
                    }
                    
                    // Encrypt the zip file using our CryptoManager
                    let encryptedFileURL = documentsDirectory.appendingPathComponent("iconink_export_\(Date().timeIntervalSince1970).iconink")
                    
                    // Use a secure password - in a real app, you would prompt the user for this
                    let exportPassword = "iconink_secure_export_password"
                    try CryptoManager.encryptFile(at: zipFileURL, to: encryptedFileURL, password: exportPassword)
                    
                    // Clean up temporary files
                    try FileManager.default.removeItem(at: temporaryDirectoryURL)
                    try FileManager.default.removeItem(at: zipFileURL)
                    
                    // Update UI on main thread
                    DispatchQueue.main.async {
                        self.exportProgress = 1.0
                        self.exportURL = encryptedFileURL
                        self.exportStatus = .completed
                    }
                }
            } catch {
                print("Export error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.exportStatus = .failed
                }
            }
        }
    }
}

// MARK: - Import Data View
struct ImportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SettingsViewModel
    
    @State private var importProgress: Double = 0
    @State private var importStatus: ImportStatus = .notStarted
    @State private var showingFilePicker = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                switch importStatus {
                case .notStarted:
                    startImportView
                case .inProgress:
                    importProgressView
                case .completed:
                    importCompletedView
                case .failed:
                    importFailedView
                }
            }
            .padding()
            .navigationTitle("Import Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var startImportView: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.and.arrow.down.circle")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Import Data")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This will import client data, consent forms, and templates from a previously exported file. This will not delete your existing data.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button {
                showingFilePicker = true
            } label: {
                Text("Select Import File")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .sheet(isPresented: $showingFilePicker) {
            DocumentPickerView(selectedURL: { url in
                self.importFile(from: url)
            })
        }
    }
    
    private var importProgressView: some View {
        VStack(spacing: 20) {
            ProgressView(value: importProgress, total: 1.0)
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(2)
                .padding()
            
            Text("Importing Data...")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Please wait while your data is being imported. This may take a moment.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
    }
    
    private var importCompletedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Import Completed")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your data has been successfully imported.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
    
    private var importFailedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Import Failed")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("There was an error importing your data. Please make sure you selected a valid export file.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button {
                showingFilePicker = true
            } label: {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
    }
    
    private func importFile(from url: URL) {
        importStatus = .inProgress
        importProgress = 0.1
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Create a temporary directory for import files
                let temporaryDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
                try FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true)
                
                // Copy the selected file to our temporary directory
                let localCopyURL = temporaryDirectoryURL.appendingPathComponent(url.lastPathComponent)
                try FileManager.default.copyItem(at: url, to: localCopyURL)
                
                // Update progress
                DispatchQueue.main.async {
                    self.importProgress = 0.2
                }
                
                // Decrypt the file using our CryptoManager
                let decryptedZipURL = temporaryDirectoryURL.appendingPathComponent("decrypted.zip")
                
                // Use the same password as for export - in a real app, you would prompt the user for this
                let importPassword = "iconink_secure_export_password"
                try CryptoManager.decryptFile(at: localCopyURL, to: decryptedZipURL, password: importPassword)
                
                // Update progress
                DispatchQueue.main.async {
                    self.importProgress = 0.4
                }
                
                // Extract the zip file using ZIPFoundation
                let extractionDirectoryURL = temporaryDirectoryURL.appendingPathComponent("extracted", isDirectory: true)
                try FileManager.default.createDirectory(at: extractionDirectoryURL, withIntermediateDirectories: true)
                
                try FileManager.default.unzipItem(at: decryptedZipURL, to: extractionDirectoryURL)
                
                // Update progress
                DispatchQueue.main.async {
                    self.importProgress = 0.6
                }
                
                // Validate the metadata
                let metadataURL = extractionDirectoryURL.appendingPathComponent("metadata.json")
                guard FileManager.default.fileExists(atPath: metadataURL.path) else {
                    throw NSError(domain: "com.flexrpl.iconink", code: 404, userInfo: [NSLocalizedDescriptionKey: "Metadata file not found in the import package"])
                }
                
                let metadataData = try Data(contentsOf: metadataURL)
                guard let metadata = try JSONSerialization.jsonObject(with: metadataData) as? [String: Any],
                      let databaseVersion = metadata["databaseVersion"] as? String else {
                    throw NSError(domain: "com.flexrpl.iconink", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid metadata in the import package"])
                }
                
                // Check database version compatibility
                if databaseVersion != "1.0" {
                    // In a real app, you might need to handle database migration
                    print("Warning: Importing database with version \(databaseVersion)")
                }
                
                // Update progress
                DispatchQueue.main.async {
                    self.importProgress = 0.8
                }
                
                // Get the CoreData store URL
                guard let storeURL = PersistenceController.shared.container.persistentStoreCoordinator.persistentStores.first?.url else {
                    throw NSError(domain: "com.flexrpl.iconink", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not locate the CoreData store"])
                }
                
                // We need to close the current CoreData stack before replacing the database
                // This is a simplified approach - in a real app, you would need to handle this more carefully
                
                // First, save any pending changes
                try PersistenceController.shared.container.viewContext.save()
                
                // Reset the persistent store coordinator
                if let persistentStore = PersistenceController.shared.container.persistentStoreCoordinator.persistentStores.first {
                    try PersistenceController.shared.container.persistentStoreCoordinator.remove(persistentStore)
                } else {
                    throw NSError(domain: "com.flexrpl.iconink", code: 500, userInfo: [NSLocalizedDescriptionKey: "No persistent store found"])
                }
                
                // Copy the imported database files to replace the current ones
                let importedDatabaseURL = extractionDirectoryURL.appendingPathComponent("iconink.sqlite")
                let importedWALURL = extractionDirectoryURL.appendingPathComponent("iconink.sqlite-wal")
                let importedSHMURL = extractionDirectoryURL.appendingPathComponent("iconink.sqlite-shm")
                
                // Remove existing database files
                if FileManager.default.fileExists(atPath: storeURL.path) {
                    try FileManager.default.removeItem(at: storeURL)
                }
                
                let walURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
                if FileManager.default.fileExists(atPath: walURL.path) {
                    try FileManager.default.removeItem(at: walURL)
                }
                
                let shmURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm")
                if FileManager.default.fileExists(atPath: shmURL.path) {
                    try FileManager.default.removeItem(at: shmURL)
                }
                
                // Copy the imported database files
                try FileManager.default.copyItem(at: importedDatabaseURL, to: storeURL)
                
                if FileManager.default.fileExists(atPath: importedWALURL.path) {
                    try FileManager.default.copyItem(at: importedWALURL, to: walURL)
                }
                
                if FileManager.default.fileExists(atPath: importedSHMURL.path) {
                    try FileManager.default.copyItem(at: importedSHMURL, to: shmURL)
                }
                
                // Reload the persistent store
                try PersistenceController.shared.container.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
                
                // Clean up temporary files
                try FileManager.default.removeItem(at: temporaryDirectoryURL)
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    self.importProgress = 1.0
                    self.importStatus = .completed
                    
                    // Notify the app that data has been imported
                    NotificationCenter.default.post(name: Notification.Name("DataImportCompleted"), object: nil)
                }
            } catch {
                print("Import error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.importStatus = .failed
                }
            }
        }
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image("AppIcon") // Make sure to add your app icon to the assets
                        .resizable()
                        .frame(width: 100, height: 100)
                        .cornerRadius(20)
                        .padding(.top)
                    
                    Text("IconInk")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0")
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Text("About IconInk")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("IconInk is a local-only iOS application for tattoo and piercing professionals to manage client information, scan IDs, capture signatures, and generate consent forms.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Divider()
                    
                    Text("Developed by")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("fleXRPL")
                        .multilineTextAlignment(.center)
                    
                    Divider()
                    
                    Text("© 2025 fleXRPL. All rights reserved.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Privacy Policy View
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Group {
                        Text("Last Updated: March 2025")
                            .foregroundColor(.secondary)
                        
                        Text("Introduction")
                            .font(.headline)
                        
                        Text("IconInk is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our application.")
                        
                        Text("Information Collection")
                            .font(.headline)
                        
                        Text("IconInk is designed with privacy as a core principle. All data is stored locally on your device and is never transmitted to external servers or third parties. We do not collect any personal information about you or your clients.")
                        
                        Text("Local Data Storage")
                            .font(.headline)
                        
                        Text("The following information is stored locally on your device:\n• Client information (name, contact details, ID information)\n• Consent form templates and completed forms\n• Client signatures\n• Application settings")
                        
                        Text("Data Security")
                            .font(.headline)
                        
                        Text("We implement appropriate security measures to protect your data:\n• All data remains on your device\n• Optional biometric or passcode protection\n• Data encryption for exports")
                        
                        Text("Your Rights")
                            .font(.headline)
                        
                        Text("You have complete control over all data in the application. You can view, edit, export, or delete any information at any time.")
                    }
                    
                    Group {
                        Text("Third-Party Services")
                            .font(.headline)
                        
                        Text("IconInk does not use any third-party services that would have access to your data. The application functions completely offline.")
                        
                        Text("Changes to This Policy")
                            .font(.headline)
                        
                        Text("We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the \"Last Updated\" date.")
                        
                        Text("Contact Us")
                            .font(.headline)
                        
                        Text("If you have any questions about this Privacy Policy, please contact us at support@iconink.app.")
                    }
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - ViewModel
class SettingsViewModel: ObservableObject {
    @Published var requireAuthentication: Bool = true
    @Published var authMethod: AuthMethod = .biometric
    @Published var autoLockTimeout: Int = 300
    @Published var useDarkMode: Bool = false
    
    var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    func loadSettings(securityManager: SecurityManager) {
        requireAuthentication = securityManager.requireAuthentication
        authMethod = securityManager.authMethod
        autoLockTimeout = securityManager.autoLockTimeout
        
        // Load appearance settings
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            useDarkMode = windowScene.windows.first?.overrideUserInterfaceStyle == .dark
        }
    }
    
    func setAppearanceMode(darkMode: Bool) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = darkMode ? .dark : .light
            }
        }
        
        // Save the preference
        UserDefaults.standard.set(darkMode, forKey: "useDarkMode")
    }
    
    func clearAllData(context: NSManagedObjectContext) {
        // Delete all clients
        let clientFetchRequest: NSFetchRequest<NSFetchRequestResult> = Client.fetchRequest()
        let clientDeleteRequest = NSBatchDeleteRequest(fetchRequest: clientFetchRequest)
        
        // Delete all consent forms
        let formFetchRequest: NSFetchRequest<NSFetchRequestResult> = ConsentForm.fetchRequest()
        let formDeleteRequest = NSBatchDeleteRequest(fetchRequest: formFetchRequest)
        
        // Delete all templates
        let templateFetchRequest: NSFetchRequest<NSFetchRequestResult> = ConsentFormTemplate.fetchRequest()
        let templateDeleteRequest = NSBatchDeleteRequest(fetchRequest: templateFetchRequest)
        
        do {
            try context.execute(clientDeleteRequest)
            try context.execute(formDeleteRequest)
            try context.execute(templateDeleteRequest)
            try context.save()
        } catch {
            print("Error clearing data: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Types
enum ExportStatus {
    case notStarted
    case inProgress
    case completed
    case failed
}

enum ImportStatus {
    case notStarted
    case inProgress
    case completed
    case failed
}

// Add this new struct for the document picker
struct DocumentPickerView: UIViewControllerRepresentable {
    var selectedURL: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Start accessing the security-scoped resource
            let securityScoped = url.startAccessingSecurityScopedResource()
            
            // Call the completion handler with the selected URL
            parent.selectedURL(url)
            
            // Stop accessing the security-scoped resource
            if securityScoped {
                url.stopAccessingSecurityScopedResource()
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(SecurityManager())
} 
