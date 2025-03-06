//
//  Client+Extensions.swift
//  iconink
//
//  Created by Garot Conklin on 2/27/25.
//

import Foundation
import CoreData

extension Client {
    // MARK: - Computed Properties
    
    var fullName: String {
        return "\(firstName ?? "") \(lastName ?? "")"
    }
    
    var age: Int {
        guard let dob = dateOfBirth else { return 0 }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
    }
    
    var formattedPhone: String? {
        guard let phone = phone, !phone.isEmpty else { return nil }
        
        // Simple formatting for US phone numbers
        if phone.count == 10 {
            let areaCode = phone.prefix(3)
            let middle = phone.dropFirst(3).prefix(3)
            let end = phone.dropFirst(6)
            return "(\(areaCode)) \(middle)-\(end)"
        }
        
        return phone
    }
    
    var formattedAddress: String? {
        var components: [String] = []
        
        if let address = address, !address.isEmpty {
            components.append(address)
        }
        
        var cityStateZip = ""
        if let city = city, !city.isEmpty {
            cityStateZip += city
        }
        
        if let state = state, !state.isEmpty {
            if !cityStateZip.isEmpty {
                cityStateZip += ", "
            }
            cityStateZip += state
        }
        
        if let zipCode = zipCode, !zipCode.isEmpty {
            if !cityStateZip.isEmpty {
                cityStateZip += " "
            }
            cityStateZip += zipCode
        }
        
        if !cityStateZip.isEmpty {
            components.append(cityStateZip)
        }
        
        return components.isEmpty ? nil : components.joined(separator: "\n")
    }
    
    // MARK: - Helper Methods
    
    /// Creates a new client with the given information
    static func createClient(
        in context: NSManagedObjectContext,
        firstName: String,
        lastName: String,
        dateOfBirth: Date,
        email: String? = nil,
        phone: String? = nil,
        address: String? = nil,
        city: String? = nil,
        state: String? = nil,
        zipCode: String? = nil,
        idType: Int16 = 0,
        idNumber: String? = nil,
        idExpirationDate: Date? = nil,
        idState: String? = nil,
        notes: String? = nil,
        isFavorite: Bool = false
    ) -> Client {
        let client = Client(context: context)
        client.firstName = firstName
        client.lastName = lastName
        client.dateOfBirth = dateOfBirth
        client.email = email
        client.phone = phone
        client.address = address
        client.city = city
        client.state = state
        client.zipCode = zipCode
        client.idType = idType
        client.idNumber = idNumber
        client.idExpirationDate = idExpirationDate
        client.idState = idState
        client.isMinor = client.age < 18
        client.hasParentalConsent = false
        client.notes = notes
        client.isFavorite = isFavorite
        client.createdAt = Date()
        client.updatedAt = Date()
        
        return client
    }
    
    /// Updates the client's timestamp
    func updateTimestamp() {
        self.updatedAt = Date()
    }
    
    /// Returns the ID type as a string
    var idTypeString: String {
        switch idType {
        case 0:
            return "Driver's License"
        case 1:
            return "State ID"
        case 2:
            return "Passport"
        case 3:
            return "Military ID"
        case 4:
            return "Other"
        default:
            return "Unknown"
        }
    }
    
    /// Returns all clients sorted by last name
    static func fetchAllClients(in context: NSManagedObjectContext) -> [Client] {
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Client.lastName, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching clients: \(error)")
            return []
        }
    }
    
    /// Returns clients that match the search text
    static func searchClients(in context: NSManagedObjectContext, searchText: String) -> [Client] {
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        
        if !searchText.isEmpty {
            let firstNamePredicate = NSPredicate(format: "firstName CONTAINS[cd] %@", searchText)
            let lastNamePredicate = NSPredicate(format: "lastName CONTAINS[cd] %@", searchText)
            let emailPredicate = NSPredicate(format: "email CONTAINS[cd] %@", searchText)
            let phonePredicate = NSPredicate(format: "phone CONTAINS[cd] %@", searchText)
            
            request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                firstNamePredicate, lastNamePredicate, emailPredicate, phonePredicate
            ])
        }
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Client.lastName, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error searching clients: \(error)")
            return []
        }
    }
    
    /// Returns favorite clients
    static func fetchFavoriteClients(in context: NSManagedObjectContext) -> [Client] {
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        request.predicate = NSPredicate(format: "isFavorite == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Client.lastName, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching favorite clients: \(error)")
            return []
        }
    }
    
    /// Returns recent clients (created in the last 30 days)
    static func fetchRecentClients(in context: NSManagedObjectContext, days: Int = 30) -> [Client] {
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        request.predicate = NSPredicate(format: "createdAt >= %@", thirtyDaysAgo as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Client.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching recent clients: \(error)")
            return []
        }
    }
} 
