//
//  ContentView.swift
//  iconink
//
//  Created by Garot Conklin on 2/27/25.
//

import SwiftUI
import CoreData
import LocalAuthentication

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var securityManager = SecurityManager.shared
    
    @State private var isAuthenticated = false
    @State private var isLocked = false
    @State private var selectedTab = 0
    @State private var showingAuthenticationView = false
    @State private var showingAddClient = false
    
    // Search and filter states
    @State private var searchText = ""
    @State private var showingFilterOptions = false
    @State private var filterFavorites = false
    @State private var sortOption = SortOption.nameAsc
    
    // Fetch clients with sorting and filtering
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.lastName, ascending: true)],
        animation: .default)
    private var clients: FetchedResults<Client>
    
    var body: some View {
        ZStack {
            if isAuthenticated {
                mainView
                    .onChange(of: securityManager.shouldLockApp()) { shouldLock in
                        if shouldLock {
                            isLocked = true
                            showingAuthenticationView = true
                        }
                    }
            } else {
                authenticationView
            }
        }
        .onAppear {
            // Check if authentication is required
            if securityManager.requiresAuthentication {
                showingAuthenticationView = true
            } else {
                isAuthenticated = true
            }
        }
        .sheet(isPresented: $showingAuthenticationView) {
            AuthenticationView(isAuthenticated: $isAuthenticated, isPresented: $showingAuthenticationView)
                .interactiveDismissDisabled()
        }
    }
    
    // Main TabView containing all app sections
    private var mainView: some View {
        TabView(selection: $selectedTab) {
            // Clients Tab
            NavigationStack {
                clientsListView
            }
            .tabItem {
                Label("Clients", systemImage: "person.2")
            }
            .tag(0)
            
            // Consent Forms Tab
            NavigationStack {
                ConsentFormListView()
            }
            .tabItem {
                Label("Forms", systemImage: "doc.text")
            }
            .tag(1)
            
            // Settings Tab
            NavigationStack {
                SettingsView()
                    .environmentObject(securityManager)
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(2)
        }
    }
    
    // Clients List View
    private var clientsListView: some View {
        List {
            // Search and filter header
            Section {
                searchAndFilterBar
            }
            
            // Clients list
            Section {
                if filteredClients.isEmpty {
                    emptyClientListView
                } else {
                    ForEach(filteredClients, id: \.self) { client in
                        NavigationLink {
                            ClientDetailView(client: client)
                        } label: {
                            clientRowView(client)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteClient(client)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                toggleFavorite(client)
                            } label: {
                                Label(
                                    client.isFavorite ? "Unfavorite" : "Favorite",
                                    systemImage: client.isFavorite ? "star.slash" : "star"
                                )
                            }
                            .tint(.yellow)
                        }
                    }
                }
            }
        }
        .navigationTitle("Clients")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddClient = true
                } label: {
                    Label("Add Client", systemImage: "person.badge.plus")
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingFilterOptions.toggle()
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        .foregroundColor(isFiltering ? .accentColor : .primary)
                }
            }
        }
        .sheet(isPresented: $showingAddClient) {
            AddClientView()
        }
        .sheet(isPresented: $showingFilterOptions) {
            filterOptionsView
        }
    }
    
    // Search and filter bar
    private var searchAndFilterBar: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search clients", text: $searchText)
                    .disableAutocorrection(true)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            if isFiltering {
                HStack {
                    if filterFavorites {
                        filterChip(title: "Favorites", systemImage: "star.fill") {
                            filterFavorites.toggle()
                        }
                    }
                    
                    filterChip(title: sortOption.displayName, systemImage: "arrow.up.arrow.down") {
                        showingFilterOptions = true
                    }
                    
                    Spacer()
                    
                    Button("Clear All") {
                        resetFilters()
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                .padding(.top, 8)
            }
        }
    }
    
    // Filter chip view
    private func filterChip(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                Image(systemName: "xmark")
                    .font(.caption)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color.accentColor.opacity(0.2))
            .foregroundColor(.accentColor)
            .cornerRadius(8)
        }
    }
    
    // Filter options view
    private var filterOptionsView: some View {
        NavigationStack {
            Form {
                Section(header: Text("Favorites")) {
                    Toggle("Show favorites only", isOn: $filterFavorites)
                }
                
                Section(header: Text("Sort By")) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button {
                            sortOption = option
                            showingFilterOptions = false
                            updateSortDescriptors()
                        } label: {
                            HStack {
                                Text(option.displayName)
                                Spacer()
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingFilterOptions = false
                        updateSortDescriptors()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        resetFilters()
                        showingFilterOptions = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // Empty client list view
    private var emptyClientListView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "No Clients Yet" : "No Matching Clients")
                .font(.headline)
            
            Text(searchText.isEmpty ? "Add your first client to get started" : "Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if !searchText.isEmpty || isFiltering {
                Button("Clear Search & Filters") {
                    resetFilters()
                    searchText = ""
                }
                .padding(.top)
            } else {
                Button {
                    showingAddClient = true
                } label: {
                    Label("Add Client", systemImage: "person.badge.plus")
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    // Client row view
    private func clientRowView(_ client: Client) -> some View {
        HStack(spacing: 15) {
            // Client initials circle
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text(clientInitials(client))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(client.firstName ?? "") \(client.lastName ?? "")")
                        .font(.headline)
                    
                    if client.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                
                if let dateOfBirth = client.dateOfBirth {
                    Text("DOB: \(dateOfBirth, formatter: DateFormatter.standardDate)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let phone = client.phone, !phone.isEmpty {
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Form count indicator
            if let forms = client.consentForms, !forms.isEmpty {
                VStack {
                    Text("\(forms.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(6)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                    
                    Text("Forms")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // Authentication view
    private var authenticationView: some View {
        VStack(spacing: 30) {
            Image("IconInk_nobg")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
            
            Text("IconInk")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Secure Client Management for Tattoo & Piercing Studios")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
            
            Button {
                showingAuthenticationView = true
            } label: {
                Text("Unlock App")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(10)
                    .padding(.horizontal, 50)
            }
            .padding(.top, 20)
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    // Get client initials
    private func clientInitials(_ client: Client) -> String {
        let firstInitial = client.firstName?.first?.uppercased() ?? ""
        let lastInitial = client.lastName?.first?.uppercased() ?? ""
        return "\(firstInitial)\(lastInitial)"
    }
    
    // Delete client
    private func deleteClient(_ client: Client) {
        withAnimation {
            viewContext.delete(client)
            saveContext()
        }
    }
    
    // Toggle favorite status
    private func toggleFavorite(_ client: Client) {
        withAnimation {
            client.isFavorite.toggle()
            saveContext()
        }
    }
    
    // Save context
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error saving context: \(nsError), \(nsError.userInfo)")
        }
    }
    
    // Reset filters
    private func resetFilters() {
        filterFavorites = false
        sortOption = .nameAsc
        updateSortDescriptors()
    }
    
    // Update sort descriptors
    private func updateSortDescriptors() {
        clients.nsSortDescriptors = sortOption.sortDescriptors
    }
    
    // Check if any filters are applied
    private var isFiltering: Bool {
        return filterFavorites || sortOption != .nameAsc
    }
    
    // Filter clients based on search text and filters
    private var filteredClients: [Client] {
        var result = clients
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { client in
                let firstName = client.firstName?.lowercased() ?? ""
                let lastName = client.lastName?.lowercased() ?? ""
                let fullName = "\(firstName) \(lastName)"
                let phone = client.phone?.lowercased() ?? ""
                let email = client.email?.lowercased() ?? ""
                
                return firstName.contains(searchText.lowercased()) ||
                       lastName.contains(searchText.lowercased()) ||
                       fullName.contains(searchText.lowercased()) ||
                       phone.contains(searchText.lowercased()) ||
                       email.contains(searchText.lowercased())
            }
        }
        
        // Apply favorites filter
        if filterFavorites {
            result = result.filter { $0.isFavorite }
        }
        
        return Array(result)
    }
}

// MARK: - Authentication View
struct AuthenticationView: View {
    @EnvironmentObject private var securityManager: SecurityManager
    @Binding var isAuthenticated: Bool
    @Binding var isPresented: Bool
    
    @State private var passcode = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image("IconInk_nobg")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                
                Text("Authentication Required")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if securityManager.authMethod == .biometric || securityManager.authMethod == .both {
                    Button {
                        authenticateWithBiometrics()
                    } label: {
                        Label(
                            securityManager.biometricType == .faceID ? "Use Face ID" : "Use Touch ID",
                            systemImage: securityManager.biometricType == .faceID ? "faceid" : "touchid"
                        )
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(10)
                        .padding(.horizontal, 50)
                    }
                }
                
                if securityManager.authMethod == .passcode || securityManager.authMethod == .both {
                    VStack(spacing: 20) {
                        Text("Enter Passcode")
                            .font(.headline)
                        
                        SecureField("Passcode", text: $passcode)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .padding(.horizontal, 50)
                        
                        Button("Unlock") {
                            authenticateWithPasscode()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(10)
                        .padding(.horizontal, 50)
                        .disabled(passcode.isEmpty)
                    }
                }
                
                Spacer()
            }
            .padding()
            .alert("Authentication Failed", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                if securityManager.authMethod == .biometric {
                    authenticateWithBiometrics()
                }
            }
        }
    }
    
    private func authenticateWithBiometrics() {
        securityManager.authenticateWithBiometrics(reason: "Unlock IconInk") { success, error in
            if success {
                isAuthenticated = true
                isPresented = false
                securityManager.updateLastActiveTime()
            } else if let error = error {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func authenticateWithPasscode() {
        if securityManager.verifyPasscode(passcode) {
            isAuthenticated = true
            isPresented = false
            securityManager.updateLastActiveTime()
        } else {
            errorMessage = "Incorrect passcode. Please try again."
            showingError = true
            passcode = ""
        }
    }
}

// MARK: - Sort Option Enum
enum SortOption: String, CaseIterable {
    case nameAsc
    case nameDesc
    case dateAsc
    case dateDesc
    
    var displayName: String {
        switch self {
        case .nameAsc:
            return "Name (A-Z)"
        case .nameDesc:
            return "Name (Z-A)"
        case .dateAsc:
            return "Date Added (Oldest)"
        case .dateDesc:
            return "Date Added (Newest)"
        }
    }
    
    var sortDescriptors: [NSSortDescriptor] {
        switch self {
        case .nameAsc:
            return [
                NSSortDescriptor(keyPath: \Client.lastName, ascending: true),
                NSSortDescriptor(keyPath: \Client.firstName, ascending: true)
            ]
        case .nameDesc:
            return [
                NSSortDescriptor(keyPath: \Client.lastName, ascending: false),
                NSSortDescriptor(keyPath: \Client.firstName, ascending: false)
            ]
        case .dateAsc:
            return [NSSortDescriptor(keyPath: \Client.createdAt, ascending: true)]
        case .dateDesc:
            return [NSSortDescriptor(keyPath: \Client.createdAt, ascending: false)]
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(SecurityManager.shared)
}
