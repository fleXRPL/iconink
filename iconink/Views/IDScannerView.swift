import SwiftUI
import AVFoundation
import Vision
import VisionKit

struct IDScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = IDScannerViewModel()
    
    var onScanComplete: (IDScanResult) -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.showDocumentScanner {
                    DocumentScannerRepresentable(
                        recognizedItems: $viewModel.recognizedItems,
                        recognizedText: $viewModel.recognizedText,
                        scanningStatus: $viewModel.scanningStatus
                    )
                    .ignoresSafeArea()
                } else {
                    scanResultsView
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
                
                if !viewModel.showDocumentScanner && viewModel.scanningStatus == .completed {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Use") {
                            onScanComplete(viewModel.scanResult)
                            dismiss()
                        }
                        .disabled(!viewModel.hasValidScan)
                    }
                }
            }
            .alert("Scanner Error", isPresented: $viewModel.showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    private var scanResultsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch viewModel.scanningStatus {
                case .notStarted:
                    startScanningView
                case .scanning:
                    ProgressView("Processing...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .completed:
                    scanResultDetailsView
                case .failed:
                    scanFailedView
                }
            }
            .padding()
        }
    }
    
    private var startScanningView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .padding()
            
            Text("Scan ID Document")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Position your ID document within the scanner frame. Make sure the document is well-lit and all text is clearly visible.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button {
                viewModel.startScanning()
            } label: {
                Text("Start Scanning")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var scanResultDetailsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Scan Results")
                .font(.title2)
                .fontWeight(.bold)
            
            if viewModel.hasValidScan {
                Group {
                    resultRow(title: "ID Type", value: viewModel.scanResult.idType)
                    
                    if !viewModel.scanResult.idNumber.isEmpty {
                        resultRow(title: "ID Number", value: viewModel.scanResult.idNumber)
                    }
                    
                    if !viewModel.scanResult.firstName.isEmpty {
                        resultRow(title: "First Name", value: viewModel.scanResult.firstName)
                    }
                    
                    if !viewModel.scanResult.lastName.isEmpty {
                        resultRow(title: "Last Name", value: viewModel.scanResult.lastName)
                    }
                    
                    if !viewModel.scanResult.dateOfBirth.isEmpty {
                        resultRow(title: "Date of Birth", value: viewModel.scanResult.dateOfBirth)
                    }
                    
                    if !viewModel.scanResult.expirationDate.isEmpty {
                        resultRow(title: "Expiration Date", value: viewModel.scanResult.expirationDate)
                    }
                    
                    if !viewModel.scanResult.address.isEmpty {
                        resultRow(title: "Address", value: viewModel.scanResult.address)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            } else {
                Text("Could not extract sufficient information from the ID. Please try scanning again or enter the information manually.")
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            HStack {
                Button {
                    viewModel.startScanning()
                } label: {
                    Text("Scan Again")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                
                if viewModel.hasValidScan {
                    Button {
                        onScanComplete(viewModel.scanResult)
                        dismiss()
                    } label: {
                        Text("Use Results")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
    
    private var scanFailedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
                .padding()
            
            Text("Scanning Failed")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(viewModel.errorMessage)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button {
                viewModel.startScanning()
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
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private func resultRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.body)
        }
    }
}

// MARK: - Document Scanner Representable
struct DocumentScannerRepresentable: UIViewControllerRepresentable {
    @Binding var recognizedItems: [VNRecognizedTextObservation]
    @Binding var recognizedText: String
    @Binding var scanningStatus: ScanningStatus
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = context.coordinator
        return documentCameraViewController
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var parent: DocumentScannerRepresentable
        
        init(_ parent: DocumentScannerRepresentable) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            parent.scanningStatus = .scanning
            
            // Process the scanned images
            DispatchQueue.global(qos: .userInitiated).async {
                var allText = ""
                var allObservations: [VNRecognizedTextObservation] = []
                
                for i in 0..<scan.pageCount {
                    let image = scan.imageOfPage(at: i)
                    let observations = self.recognizeText(from: image)
                    allObservations.append(contentsOf: observations)
                    
                    for observation in observations {
                        if let topCandidate = observation.topCandidates(1).first {
                            allText += topCandidate.string + "\n"
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.parent.recognizedItems = allObservations
                    self.parent.recognizedText = allText
                    self.parent.scanningStatus = .completed
                }
            }
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            DispatchQueue.main.async {
                self.parent.scanningStatus = .failed
            }
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            DispatchQueue.main.async {
                self.parent.scanningStatus = .notStarted
            }
        }
        
        private func recognizeText(from image: UIImage) -> [VNRecognizedTextObservation] {
            guard let cgImage = image.cgImage else { return [] }
            
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            
            do {
                try requestHandler.perform([request])
                return request.results as? [VNRecognizedTextObservation] ?? []
            } catch {
                print("Error recognizing text: \(error.localizedDescription)")
                return []
            }
        }
    }
}

// MARK: - ViewModel
class IDScannerViewModel: ObservableObject {
    @Published var showDocumentScanner = false
    @Published var recognizedItems: [VNRecognizedTextObservation] = []
    @Published var recognizedText = ""
    @Published var scanningStatus: ScanningStatus = .notStarted
    @Published var showingErrorAlert = false
    @Published var errorMessage = "An error occurred while scanning. Please try again."
    
    var scanResult = IDScanResult()
    
    var hasValidScan: Bool {
        return !scanResult.idNumber.isEmpty || 
               (!scanResult.firstName.isEmpty && !scanResult.lastName.isEmpty)
    }
    
    func startScanning() {
        // Check camera permission
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.showDocumentScanner = true
            self.scanningStatus = .scanning
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.showDocumentScanner = true
                        self.scanningStatus = .scanning
                    } else {
                        self.showCameraPermissionError()
                    }
                }
            }
        case .denied, .restricted:
            showCameraPermissionError()
        @unknown default:
            showCameraPermissionError()
        }
    }
    
    private func showCameraPermissionError() {
        errorMessage = "Camera access is required to scan IDs. Please enable camera access in Settings."
        showingErrorAlert = true
        scanningStatus = .failed
    }
    
    // This method would be called when the scan is completed
    func processScanResults() {
        guard !recognizedText.isEmpty else {
            scanningStatus = .failed
            errorMessage = "No text was recognized in the scan. Please try again."
            return
        }
        
        // Parse the recognized text to extract ID information
        scanResult = processRecognizedText(recognizedText)
        
        if !hasValidScan {
            errorMessage = "Could not extract sufficient information from the ID. Please try scanning again."
            // We don't set scanningStatus to .failed here because we still want to show the partial results
        }
    }
    
    private func processRecognizedText(_ text: String) -> IDScanResult {
        var result = IDScanResult()
        
        // Split processing into smaller functions
        result.name = extractName(from: text)
        result.dateOfBirth = extractDateOfBirth(from: text)
        result.idNumber = extractIDNumber(from: text)
        result.expirationDate = extractExpirationDate(from: text)
        result.address = extractAddress(from: text)
        
        return result
    }
    
    private func extractName(from text: String) -> String {
        // Name extraction logic
        let lines = text.components(separatedBy: .newlines)
        for (index, line) in lines.enumerated() where line.contains("NAME") && index + 1 < lines.count {
            return lines[index + 1].trimmingCharacters(in: .whitespaces)
        }
        return ""
    }
    
    private func extractDateOfBirth(from text: String) -> String {
        // Date of birth extraction logic
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("DOB") || line.contains("BIRTH") {
                let components = line.components(separatedBy: .whitespaces)
                for component in components {
                    if component.contains("/") || component.contains("-") {
                        return component
                    }
                }
            }
        }
        return ""
    }
    
    private func extractIDNumber(from text: String) -> String {
        // ID number extraction logic
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("DL") || line.contains("LIC") || line.contains("ID") {
                let components = line.components(separatedBy: .whitespaces)
                for component in components {
                    if component.count >= 6 && component.count <= 12 {
                        return component
                    }
                }
            }
        }
        return ""
    }
    
    private func extractExpirationDate(from text: String) -> String {
        // Expiration date extraction logic
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("EXP") || line.contains("EXPIRES") {
                let components = line.components(separatedBy: .whitespaces)
                for component in components {
                    if component.contains("/") || component.contains("-") {
                        return component
                    }
                }
            }
        }
        return ""
    }
    
    private func extractAddress(from text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        for (index, line) in lines.enumerated() where (line.contains("ADDR") || line.contains("ADDRESS")) && index + 1 < lines.count {
            return lines[index + 1].trimmingCharacters(in: .whitespaces)
        }
        return ""
    }
    
    private func processScannedText(_ text: String) -> ClientInfo? {
        let components = extractTextComponents(from: text)
        return createClientInfo(from: components)
    }
    
    private func extractTextComponents(from text: String) -> [String: String] {
        var components: [String: String] = [:]
        
        components["name"] = extractName(from: text)
        components["dob"] = extractDateOfBirth(from: text)
        components["idNumber"] = extractIDNumber(from: text)
        components["expiration"] = extractExpirationDate(from: text)
        components["state"] = extractState(from: text)
        
        return components
    }
    
    private func extractState(from text: String) -> String? {
        // Implementation of extractState function
        return nil // Placeholder return, actual implementation needed
    }
    
    private func createClientInfo(from components: [String: String]) -> ClientInfo? {
        // Implementation of createClientInfo function
        return nil // Placeholder return, actual implementation needed
    }
}

// MARK: - Supporting Types
enum ScanningStatus {
    case notStarted
    case scanning
    case completed
    case failed
}

struct IDScanResult {
    var idType: String = ""
    var idNumber: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var dateOfBirth: String = ""
    var expirationDate: String = ""
    var address: String = ""
    
    // Convert string dates to Date objects if needed
    var dateOfBirthAsDate: Date? {
        return formatStringToDate(dateOfBirth)
    }
    
    var expirationDateAsDate: Date? {
        return formatStringToDate(expirationDate)
    }
    
    private func formatStringToDate(_ dateString: String) -> Date? {
        guard !dateString.isEmpty else { return nil }
        
        let dateFormatter = DateFormatter()
        
        // Try different date formats
        let dateFormats = ["MM/dd/yyyy", "yyyy-MM-dd", "dd/MM/yyyy", "yyyy/MM/dd"]
        
        for format in dateFormats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
}

#Preview {
    IDScannerView { _ in
        // Handle scan result in preview
    }
} 
