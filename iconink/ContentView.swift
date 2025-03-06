//
//  ContentView.swift
//  iconink
//
//  Created by Garot Conklin on 2/27/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isAppLocked = false
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if isAppLocked {
                AppLockView(isAppLocked: $isAppLocked)
            } else {
                TabView(selection: $selectedTab) {
                    // Clients tab
                    NavigationStack {
                        ClientListView()
                            .navigationTitle("Clients")
                    }
                    .tabItem {
                        Label("Clients", systemImage: "person.2")
                    }
                    .tag(0)
                    
                    // Forms tab
                    NavigationStack {
                        ConsentFormListView()
                            .navigationTitle("Forms")
                    }
                    .tabItem {
                        Label("Forms", systemImage: "doc.text")
                    }
                    .tag(1)
                    
                    // ID Scanner tab
                    NavigationStack {
                        IDScannerView()
                            .navigationTitle("Scan ID")
                    }
                    .tabItem {
                        Label("Scan ID", systemImage: "camera")
                    }
                    .tag(2)
                    
                    // Settings tab
                    NavigationStack {
                        SettingsView(isAppLocked: $isAppLocked)
                            .navigationTitle("Settings")
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(3)
                }
                .onAppear {
                    // Check if app should be locked when returning from background
                    if SecurityManager.shared.shouldLockApp() {
                        isAppLocked = true
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    // Update last active time when app goes to background
                    SecurityManager.shared.updateLastActiveTime()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Check if app should be locked when returning from background
                    if SecurityManager.shared.shouldLockApp() {
                        isAppLocked = true
                    }
                }
            }
        }
    }
}

// MARK: - App Lock View

struct AppLockView: View {
    @Binding var isAppLocked: Bool
    @State private var passcode = ""
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 70))
                .foregroundColor(.accentColor)
                .padding(.bottom, 20)
            
            Text("IconInk is locked")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Please authenticate to continue")
                .foregroundColor(.secondary)
            
            if showError {
                Text("Authentication failed. Please try again.")
                    .foregroundColor(.red)
                    .padding(.top, 10)
            }
            
            Spacer().frame(height: 30)
            
            // Biometric authentication button
            if SecurityManager.shared.useBiometrics && SecurityManager.shared.isBiometricAvailable {
                Button(action: authenticateWithBiometrics) {
                    Label(
                        SecurityManager.shared.biometricType == .faceID ? "Use Face ID" : "Use Touch ID",
                        systemImage: SecurityManager.shared.biometricType == .faceID ? "faceid" : "touchid"
                    )
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            
            // Passcode entry (simplified for MVP)
            if SecurityManager.shared.usePasscode {
                SecureField("Enter Passcode", text: $passcode)
                    .textContentType(.oneTimeCode)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                Button("Unlock") {
                    verifyPasscode()
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            // Automatically prompt for biometric authentication when view appears
            if SecurityManager.shared.useBiometrics && SecurityManager.shared.isBiometricAvailable {
                authenticateWithBiometrics()
            }
        }
    }
    
    private func authenticateWithBiometrics() {
        SecurityManager.shared.authenticateWithBiometrics(reason: "Unlock IconInk") { success, _ in
            if success {
                isAppLocked = false
            } else {
                showError = true
            }
        }
    }
    
    private func verifyPasscode() {
        if SecurityManager.shared.verifyPasscode(passcode) {
            isAppLocked = false
            showError = false
        } else {
            showError = true
            passcode = ""
        }
    }
}

// MARK: - Client List View

struct ClientListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.lastName, ascending: true)],
        animation: .default)
    private var clients: FetchedResults<Client>
    
    @State private var searchText = ""
    @State private var showingAddClient = false
    @State private var filterOption = FilterOption.all
    
    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "All"
        case favorites = "Favorites"
        case recent = "Recent"
        
        var id: String { self.rawValue }
    }
    
    var filteredClients: [Client] {
        if searchText.isEmpty {
            switch filterOption {
            case .all:
                return Array(clients)
            case .favorites:
                return clients.filter { $0.isFavorite }
            case .recent:
                let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                return clients.filter { $0.createdAt ?? Date() > thirtyDaysAgo }
            }
        } else {
            return clients.filter {
                let fullName = "\($0.firstName ?? "") \($0.lastName ?? "")"
                return fullName.localizedCaseInsensitiveContains(searchText) ||
                       ($0.email ?? "").localizedCaseInsensitiveContains(searchText) ||
                       ($0.phone ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack {
            // App Icon and Title
            HStack {
                Image("IconInk_nobg")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 44)
                Spacer()
            }
            .padding(.horizontal)
            
            // Filter picker
            Picker("Filter", selection: $filterOption) {
                ForEach(FilterOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            List {
                ForEach(filteredClients, id: \.self) { client in
                    NavigationLink(destination: ClientDetailView(client: client)) {
                        ClientRowView(client: client)
                    }
                }
                .onDelete(perform: deleteClients)
            }
            .searchable(text: $searchText, prompt: "Search clients")
            .overlay {
                if clients.isEmpty {
                    ContentUnavailableView {
                        Label("No Clients", systemImage: "person.2.slash")
                    } description: {
                        Text("Add a client to get started")
                    } actions: {
                        Button("Add Client") {
                            showingAddClient = true
                        }
                    }
                } else if filteredClients.isEmpty {
                    ContentUnavailableView {
                        Label("No Results", systemImage: "magnifyingglass")
                    } description: {
                        Text("Try a different search term or filter")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: { showingAddClient = true }, label: { 
                        Label("Add Client", systemImage: "plus")
                    })
                }
            }
            .sheet(isPresented: $showingAddClient) {
                AddClientView()
            }
        }
    }
    
    private func deleteClients(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredClients[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error deleting clients: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// MARK: - Client Row View

struct ClientRowView: View {
    let client: Client
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(client.fullName)
                    .font(.headline)
                
                if let dob = client.dateOfBirth {
                    Text("DOB: \(dob, formatter: DateFormatter.shortDate)")
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
            
            if client.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
        }
    }
}

// MARK: - Client Detail View (Placeholder)

struct ClientDetailView: View {
    let client: Client
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isEditingClient = false
    @State private var showingIDScanner = false
    @State private var showingNewForm = false
    
    var body: some View {
        List {
            Section("Personal Information") {
                LabeledContent("Name", value: client.fullName)
                
                if let dob = client.dateOfBirth {
                    LabeledContent("Date of Birth", value: dob, format: .dateTime.month().day().year())
                    LabeledContent("Age", value: "\(client.age) years")
                }
                
                if let email = client.email, !email.isEmpty {
                    LabeledContent("Email", value: email)
                }
                
                if let phone = client.phone, !phone.isEmpty {
                    LabeledContent("Phone", value: phone)
                }
                
                if let address = client.address, !address.isEmpty {
                    LabeledContent("Address", value: address)
                    
                    if let city = client.city, !city.isEmpty {
                        LabeledContent("City", value: city)
                    }
                    
                    if let state = client.state, !state.isEmpty {
                        LabeledContent("State", value: state)
                    }
                    
                    if let zipCode = client.zipCode, !zipCode.isEmpty {
                        LabeledContent("ZIP Code", value: zipCode)
                    }
                }
            }
            
            Section("ID Information") {
                LabeledContent("ID Type", value: client.idTypeString)
                
                if let idNumber = client.idNumber, !idNumber.isEmpty {
                    LabeledContent("ID Number", value: idNumber)
                }
                
                if let idState = client.idState, !idState.isEmpty {
                    LabeledContent("ID State", value: idState)
                }
                
                if let idExpirationDate = client.idExpirationDate {
                    LabeledContent("Expiration Date", value: idExpirationDate, format: .dateTime.month().day().year())
                }
                
                Button("Scan ID") {
                    showingIDScanner = true
                }
            }
            
            if let idImages = client.idImages, idImages.count > 0 { // swiftlint:disable:this empty_count
                Section("ID Images") {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(Array(idImages as? Set<IDImage> ?? []), id: \.self) { idImage in
                                if let image = idImage.loadImage() {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 150)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .frame(height: 170)
                }
            }
            
            if let forms = client.consentForms, forms.count > 0 { // swiftlint:disable:this empty_count
                Section("Consent Forms") {
                    ForEach(Array(forms as? Set<ConsentForm> ?? []), id: \.self) { form in
                        NavigationLink(destination: Text("Form details coming soon")) {
                            VStack(alignment: .leading) {
                                Text(form.formTitle ?? "Untitled Form")
                                    .font(.headline)
                                
                                if let serviceDate = form.serviceDate {
                                    Text(serviceDate, formatter: DateFormatter.shortDate)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(form.formTypeString)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Button("New Consent Form") {
                        showingNewForm = true
                    }
                }
            } else {
                Section {
                    Button("Create Consent Form") {
                        showingNewForm = true
                    }
                }
            }
            
            if let notes = client.notes, notes.count > 0 { // swiftlint:disable:this empty_count
                Section("Notes") {
                    Text(notes)
                }
            }
        }
        .navigationTitle(client.fullName)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isEditingClient = true }, label: {
                    Text("Edit")
                })
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: toggleFavorite) {
                    Image(systemName: client.isFavorite ? "star.fill" : "star")
                        .foregroundColor(client.isFavorite ? .yellow : .gray)
                }
            }
        }
        .sheet(isPresented: $isEditingClient) {
            EditClientView(client: client)
        }
        .sheet(isPresented: $showingIDScanner) {
            Text("ID Scanner view coming soon")
        }
        .sheet(isPresented: $showingNewForm) {
            Text("New consent form view coming soon")
        }
    }
    
    private func toggleFavorite() {
        client.isFavorite = !client.isFavorite
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error toggling favorite: \(nsError), \(nsError.userInfo)")
        }
    }
}

// MARK: - Edit Client View

struct EditClientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let client: Client
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var dateOfBirth: Date
    @State private var email: String
    @State private var phone: String
    @State private var address: String
    @State private var city: String
    @State private var state: String
    @State private var zipCode: String
    @State private var notes: String
    @State private var isFavorite: Bool
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(client: Client) {
        self.client = client
        _firstName = State(initialValue: client.firstName ?? "")
        _lastName = State(initialValue: client.lastName ?? "")
        _dateOfBirth = State(initialValue: client.dateOfBirth ?? Date())
        _email = State(initialValue: client.email ?? "")
        _phone = State(initialValue: client.phone ?? "")
        _address = State(initialValue: client.address ?? "")
        _city = State(initialValue: client.city ?? "")
        _state = State(initialValue: client.state ?? "")
        _zipCode = State(initialValue: client.zipCode ?? "")
        _notes = State(initialValue: client.notes ?? "")
        _isFavorite = State(initialValue: client.isFavorite)
    }
    
    var isValidForm: Bool {
        !firstName.trimmed.isEmpty && !lastName.trimmed.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                    DatePicker("Date of Birth", selection: $dateOfBirth, in: ...Date(), displayedComponents: .date)
                }
                
                Section("Contact Information") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section("Address") {
                    TextField("Street Address", text: $address)
                        .textContentType(.streetAddressLine1)
                    TextField("City", text: $city)
                        .textContentType(.addressCity)
                    TextField("State", text: $state)
                        .textContentType(.addressState)
                    TextField("ZIP Code", text: $zipCode)
                        .textContentType(.postalCode)
                        .keyboardType(.numberPad)
                }
                
                Section("Additional Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Toggle("Favorite", isOn: $isFavorite)
                }
            }
            .navigationTitle("Edit Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        validateAndSave()
                    }
                    .disabled(!isValidForm)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func validateAndSave() {
        // Validate email if provided
        if !email.isEmpty && !email.isValidEmail {
            alertMessage = "Please enter a valid email address"
            showingAlert = true
            return
        }
        
        // Validate phone if provided
        if !phone.isEmpty && !phone.isValidUSPhoneNumber {
            alertMessage = "Please enter a valid phone number"
            showingAlert = true
            return
        }
        
        // Validate ZIP code if provided
        if !zipCode.isEmpty && !zipCode.isValidZIPCode {
            alertMessage = "Please enter a valid ZIP code"
            showingAlert = true
            return
        }
        
        withAnimation {
            client.firstName = firstName.trimmed
            client.lastName = lastName.trimmed
            client.dateOfBirth = dateOfBirth
            client.email = email.isEmpty ? nil : email.trimmed
            client.phone = phone.isEmpty ? nil : phone.trimmed
            client.address = address.isEmpty ? nil : address.trimmed
            client.city = city.isEmpty ? nil : city.trimmed
            client.state = state.isEmpty ? nil : state.trimmed
            client.zipCode = zipCode.isEmpty ? nil : zipCode.trimmed
            client.notes = notes.isEmpty ? nil : notes.trimmed
            client.updatedAt = Date()
            client.isFavorite = isFavorite
            client.isMinor = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0 < 18
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                let nsError = error as NSError
                alertMessage = "Error saving client: \(nsError.localizedDescription)"
                showingAlert = true
            }
        }
    }
}

// MARK: - Add Client View

struct AddClientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dateOfBirth = Date()
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var notes = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var isValidForm: Bool {
        !firstName.trimmed.isEmpty && !lastName.trimmed.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                    DatePicker("Date of Birth", selection: $dateOfBirth, in: ...Date(), displayedComponents: .date)
                }
                
                Section("Contact Information") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section("Address") {
                    TextField("Street Address", text: $address)
                        .textContentType(.streetAddressLine1)
                    TextField("City", text: $city)
                        .textContentType(.addressCity)
                    TextField("State", text: $state)
                        .textContentType(.addressState)
                    TextField("ZIP Code", text: $zipCode)
                        .textContentType(.postalCode)
                        .keyboardType(.numberPad)
                }
                
                Section("Additional Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        validateAndSave()
                    }
                    .disabled(!isValidForm)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func validateAndSave() {
        // Validate email if provided
        if !email.isEmpty && !email.isValidEmail {
            alertMessage = "Please enter a valid email address"
            showingAlert = true
            return
        }
        
        // Validate phone if provided
        if !phone.isEmpty && !phone.isValidUSPhoneNumber {
            alertMessage = "Please enter a valid phone number"
            showingAlert = true
            return
        }
        
        // Validate ZIP code if provided
        if !zipCode.isEmpty && !zipCode.isValidZIPCode {
            alertMessage = "Please enter a valid ZIP code"
            showingAlert = true
            return
        }
        
        withAnimation {
            let newClient = Client(context: viewContext)
            newClient.firstName = firstName.trimmed
            newClient.lastName = lastName.trimmed
            newClient.dateOfBirth = dateOfBirth
            newClient.email = email.isEmpty ? nil : email.trimmed
            newClient.phone = phone.isEmpty ? nil : phone.trimmed
            newClient.address = address.isEmpty ? nil : address.trimmed
            newClient.city = city.isEmpty ? nil : city.trimmed
            newClient.state = state.isEmpty ? nil : state.trimmed
            newClient.zipCode = zipCode.isEmpty ? nil : zipCode.trimmed
            newClient.notes = notes.isEmpty ? nil : notes.trimmed
            newClient.createdAt = Date()
            newClient.updatedAt = Date()
            newClient.idType = 0 // Default to driver's license
            newClient.isMinor = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0 < 18
            newClient.hasParentalConsent = false
            newClient.isFavorite = false
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                let nsError = error as NSError
                alertMessage = "Error saving client: \(nsError.localizedDescription)"
                showingAlert = true
            }
        }
    }
}

// MARK: - Consent Form List View (Placeholder)

struct ConsentFormListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ConsentForm.serviceDate, ascending: false)],
        animation: .default)
    private var forms: FetchedResults<ConsentForm>
    
    @State private var searchText = ""
    @State private var showingAddForm = false
    @State private var filterOption = FilterOption.all
    
    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "All"
        case draft = "Draft"
        case signed = "Signed"
        case completed = "Completed"
        
        var id: String { self.rawValue }
    }
    
    var filteredForms: [ConsentForm] {
        if searchText.isEmpty {
            switch filterOption {
            case .all:
                return Array(forms)
            case .draft:
                return forms.filter { $0.formStatus == 0 }
            case .signed:
                return forms.filter { $0.formStatus == 1 }
            case .completed:
                return forms.filter { $0.formStatus == 2 }
            }
        } else {
            return forms.filter {
                ($0.formTitle ?? "").localizedCaseInsensitiveContains(searchText) ||
                ($0.client?.fullName ?? "").localizedCaseInsensitiveContains(searchText) ||
                ($0.serviceDescription ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack {
            // Filter picker
            Picker("Filter", selection: $filterOption) {
                ForEach(FilterOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            List {
                ForEach(filteredForms, id: \.self) { form in
                    NavigationLink(destination: Text("Form details coming soon")) {
                        VStack(alignment: .leading) {
                            Text(form.formTitle ?? "Untitled Form")
                                .font(.headline)
                            
                            if let client = form.client {
                                Text("Client: \(client.fullName)")
                                    .font(.subheadline)
                            }
                            
                            HStack {
                                Text(form.formTypeString)
                                
                                Spacer()
                                
                                Text(form.formStatusString)
                                    .foregroundColor(statusColor(for: form.formStatus))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(statusColor(for: form.formStatus).opacity(0.2))
                                    .cornerRadius(4)
                            }
                            .font(.caption)
                            
                            if let serviceDate = form.serviceDate {
                                Text("Date: \(serviceDate, formatter: DateFormatter.shortDate)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteForms)
            }
            .searchable(text: $searchText, prompt: "Search forms")
            .overlay {
                if forms.isEmpty {
                    ContentUnavailableView {
                        Label("No Forms", systemImage: "doc.text.slash")
                    } description: {
                        Text("Create a consent form to get started")
                    } actions: {
                        Button("Create Form") {
                            showingAddForm = true
                        }
                    }
                } else if filteredForms.isEmpty {
                    ContentUnavailableView {
                        Label("No Results", systemImage: "magnifyingglass")
                    } description: {
                        Text("Try a different search term or filter")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: { showingAddForm = true }, label: {
                        Label("Add Form", systemImage: "plus")
                    })
                }
            }
            .sheet(isPresented: $showingAddForm) {
                Text("New form view coming soon")
            }
        }
    }
    
    private func statusColor(for status: Int16) -> Color {
        switch status {
        case 0: // Draft
            return .gray
        case 1: // Signed
            return .blue
        case 2: // Completed
            return .green
        case 3: // Archived
            return .purple
        default:
            return .gray
        }
    }
    
    private func deleteForms(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredForms[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error deleting forms: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// MARK: - ID Scanner View (Placeholder)

struct IDScannerView: View {
    @State private var showingCamera = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 100))
                .foregroundColor(.accentColor)
                .padding()
            
            Text("ID Scanner")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Scan a client's ID to extract information")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer().frame(height: 20)
            
            Button(action: { showingCamera = true }, label: {
                Label("Scan ID", systemImage: "camera")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            })
            .padding(.horizontal)
            
            Spacer()
            
            Text("This feature allows you to scan a client's ID and automatically extract their information.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .sheet(isPresented: $showingCamera) {
            Text("Camera view coming soon")
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Binding var isAppLocked: Bool
    @AppStorage("useBiometrics") private var useBiometrics = true
    @AppStorage("usePasscode") private var usePasscode = false
    @AppStorage("autoLockTimeout") private var autoLockTimeout = 5
    @State private var showingSetPasscode = false
    @State private var showingAbout = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTerms = false
    
    var body: some View {
        List {
            Section("Security") {
                if SecurityManager.shared.isBiometricAvailable {
                    Toggle("Use \(SecurityManager.shared.biometricType.displayName)", isOn: $useBiometrics)
                        .onChange(of: useBiometrics) { _, newValue in
                            SecurityManager.shared.useBiometrics = newValue
                        }
                }
                
                Toggle("Use Passcode", isOn: $usePasscode)
                    .onChange(of: usePasscode) { _, newValue in
                        if newValue {
                            showingSetPasscode = true
                        } else {
                            SecurityManager.shared.removePasscode()
                        }
                    }
                
                Button("Change Passcode") {
                    showingSetPasscode = true
                }
                .disabled(!usePasscode)
                
                Picker("Auto-Lock Timeout", selection: $autoLockTimeout) {
                    Text("Immediate").tag(0)
                    Text("1 minute").tag(1)
                    Text("5 minutes").tag(5)
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("Never").tag(-1)
                }
                .onChange(of: autoLockTimeout) { _, newValue in
                    SecurityManager.shared.autoLockTimeout = newValue
                }
                
                Button("Lock Now") {
                    isAppLocked = true
                }
                .foregroundColor(.red)
            }
            
            Section("Data Management") {
                Button("Export Data") {
                    // Export functionality will be implemented later
                }
                
                Button("Import Data") {
                    // Import functionality will be implemented later
                }
                
                Button("Clear All Data") {
                    // Clear data functionality will be implemented later
                }
                .foregroundColor(.red)
            }
            
            Section("About") {
                Button("About IconInk") {
                    showingAbout = true
                }
                
                Button("Privacy Policy") {
                    showingPrivacyPolicy = true
                }
                
                Button("Terms of Service") {
                    showingTerms = true
                }
                
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Build", value: "1")
            }
        }
        .sheet(isPresented: $showingSetPasscode) {
            Text("Set passcode view coming soon")
        }
        .sheet(isPresented: $showingAbout) {
            Text("About view coming soon")
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            Text("Privacy policy view coming soon")
        }
        .sheet(isPresented: $showingTerms) {
            Text("Terms of service view coming soon")
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
