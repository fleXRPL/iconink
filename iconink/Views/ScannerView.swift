import SwiftUI
import CoreData

struct ScannerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingNewScan = false
    @State private var selectedClient: Client?
    @State private var isCapturingFront = true
    @State private var showingClientSelection = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // Scanner start view
                VStack(spacing: 20) {
                    // Icon and title
                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                    
                    Text("ID Scanner")
                        .font(.title)
                        .bold()
                    
                    Text("Scan client ID cards to automatically capture and verify their identification information")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Spacer().frame(height: 40)
                    
                    // Start new scan
                    Button {
                        showingClientSelection = true
                    } label: {
                        Label("New ID Scan", systemImage: "camera.viewfinder")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        instructionRow(icon: "1.circle.fill", text: "Select or create a client")
                        instructionRow(icon: "2.circle.fill", text: "Position ID within the frame")
                        instructionRow(icon: "3.circle.fill", text: "Capture both front and back")
                        instructionRow(icon: "4.circle.fill", text: "Verify extracted information")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Scanner")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        AddClientView()
                    } label: {
                        Label("Add Client", systemImage: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingClientSelection) {
                ClientSelectionView(onSelectClient: { client in
                    self.selectedClient = client
                    self.isCapturingFront = true
                    self.showingNewScan = true
                    self.showingClientSelection = false
                })
            }
            .sheet(isPresented: $showingNewScan, onDismiss: {
                // If we just scanned the front, now prompt for the back
                if isCapturingFront, let client = selectedClient {
                    isCapturingFront = false
                    // Short delay to allow the sheet to fully dismiss before showing again
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingNewScan = true
                    }
                } else {
                    // Reset after capturing both sides
                    selectedClient = nil
                }
            }) {
                if let client = selectedClient {
                    CameraView(isCapturingFront: isCapturingFront, client: client)
                }
            }
        }
    }
    
    private func instructionRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

struct ClientSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    var onSelectClient: (Client) -> Void
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.lastName, ascending: true)],
        animation: .default)
    private var clients: FetchedResults<Client>
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(clients) { client in
                    Button {
                        onSelectClient(client)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(client.firstName) \(client.lastName)")
                                    .font(.headline)
                                if let phone = client.phone {
                                    Text(phone)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                
                // Create new client option
                NavigationLink {
                    AddClientView()
                } label: {
                    Label("Create New Client", systemImage: "person.badge.plus")
                        .foregroundColor(.blue)
                }
            }
            .navigationTitle("Select Client")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ScannerView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
