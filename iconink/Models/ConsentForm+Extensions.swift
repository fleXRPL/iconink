//
//  ConsentForm+Extensions.swift
//  iconink
//
//  Created by Garot Conklin on 2/27/25.
//

import Foundation
import CoreData
import UIKit

// MARK: - JSON Codable Structures

/// Structure for tattoo details that can be encoded/decoded to/from JSON
struct TattooDetails: Codable {
    var bodyLocation: String
    var design: String
    var size: String
    var colors: [String]
    var isCustom: Bool
    var includesTouchup: Bool
    var allergies: String?
}

/// Structure for piercing details that can be encoded/decoded to/from JSON
struct PiercingDetails: Codable {
    var piercingLocation: String
    var jewelryType: String
    var jewelryMaterial: String
    var jewelryGauge: String
    var allergies: String?
}

// MARK: - Helper Types

/// Text attributes for PDF rendering
struct PDFTextAttributes {
    let title: [NSAttributedString.Key: Any]
    let header: [NSAttributedString.Key: Any]
    let body: [NSAttributedString.Key: Any]
    let paragraph: NSMutableParagraphStyle
}

extension ConsentForm {
    // MARK: - Computed Properties
    
    /// Returns the form type as a string
    var formTypeString: String {
        switch formType {
        case 0:
            return "Tattoo"
        case 1:
            return "Piercing"
        case 2:
            return "Microblading"
        case 3:
            return "Other"
        default:
            return "Unknown"
        }
    }
    
    /// Returns the form status as a string
    var formStatusString: String {
        switch formStatus {
        case 0:
            return "Draft"
        case 1:
            return "Signed"
        case 2:
            return "Completed"
        case 3:
            return "Archived"
        default:
            return "Unknown"
        }
    }
    
    /// Gets the tattoo details from JSON
    var tattooDetails: TattooDetails? {
        guard let json = tattooDetailsJSON, !json.isEmpty else { return nil }
        
        let decoder = JSONDecoder()
        do {
            guard let data = json.data(using: .utf8) else {
                print("Error converting JSON string to data")
                return nil
            }
            return try decoder.decode(TattooDetails.self, from: data)
        } catch {
            print("Error decoding tattoo details: \(error)")
            return nil
        }
    }
    
    /// Sets the tattoo details as JSON
    func setTattooDetails(_ details: TattooDetails) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(details)
            if let json = String(data: data, encoding: .utf8) {
                self.tattooDetailsJSON = json
            }
        } catch {
            print("Error encoding tattoo details: \(error)")
        }
    }
    
    /// Gets the piercing details from JSON
    var piercingDetails: PiercingDetails? {
        guard let json = piercingDetailsJSON, !json.isEmpty else { return nil }
        
        let decoder = JSONDecoder()
        do {
            guard let data = json.data(using: .utf8) else {
                print("Error converting JSON string to data")
                return nil
            }
            return try decoder.decode(PiercingDetails.self, from: data)
        } catch {
            print("Error decoding piercing details: \(error)")
            return nil
        }
    }
    
    /// Sets the piercing details as JSON
    func setPiercingDetails(_ details: PiercingDetails) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(details)
            if let json = String(data: data, encoding: .utf8) {
                self.piercingDetailsJSON = json
            }
        } catch {
            print("Error encoding piercing details: \(error)")
        }
    }
    
    /// Gets the acknowledged risks from JSON
    var acknowledgedRisks: [String] {
        guard let json = acknowledgedRisksJSON, !json.isEmpty else { return [] }
        
        let decoder = JSONDecoder()
        do {
            guard let data = json.data(using: .utf8) else {
                print("Error converting JSON string to data")
                return []
            }
            return try decoder.decode([String].self, from: data)
        } catch {
            print("Error decoding acknowledged risks: \(error)")
            return []
        }
    }
    
    /// Sets the acknowledged risks as JSON
    func setAcknowledgedRisks(_ risks: [String]) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(risks)
            if let json = String(data: data, encoding: .utf8) {
                self.acknowledgedRisksJSON = json
            }
        } catch {
            print("Error encoding acknowledged risks: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Creates a new consent form with the given information
    static func createConsentForm(
        in context: NSManagedObjectContext,
        formTitle: String,
        formType: Int16,
        serviceDescription: String,
        aftercareInstructions: String? = nil,
        client: Client? = nil
    ) -> ConsentForm {
        let form = ConsentForm(context: context)
        form.formTitle = formTitle
        form.formType = formType
        form.formStatus = 0 // Draft
        form.serviceDate = Date()
        form.serviceDescription = serviceDescription
        form.aftercareInstructions = aftercareInstructions
        form.client = client
        form.createdAt = Date()
        form.updatedAt = Date()
        form.acknowledgedRisksJSON = "[]" // Empty array
        
        return form
    }
    
    /// Updates the form's timestamp
    func updateTimestamp() {
        self.updatedAt = Date()
    }
    
    /// Generates a PDF of the consent form and saves it to disk
    func generatePDF() -> URL? {
        // Create a PDF renderer
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        // Generate a unique filename
        let fileName = UUID().uuidString + ".pdf"
        let pdfPath = "ConsentForms/" + fileName
        
        // Create directory and get file URL
        guard let fileURL = prepareFileURL(forPath: pdfPath) else { return nil }
        
        // Generate the PDF
        do {
            try renderer.writePDF(to: fileURL) { context in
                // First page
                context.beginPage()
                
                // Set up fonts and attributes
                let attributes = createTextAttributes()
                
                // Draw content
                var yPosition = drawHeader(in: context, with: attributes, pageWidth: pageWidth)
                
                // Draw client information
                yPosition = drawClientInformation(in: context, with: attributes, yPosition: yPosition)
                
                // Draw service information
                yPosition = drawServiceInformation(in: context, with: attributes, yPosition: yPosition, pageWidth: pageWidth)
                
                // Draw specific details based on form type
                yPosition = drawFormTypeSpecificDetails(in: context, with: attributes, yPosition: yPosition)
                
                // Draw risk acknowledgments
                yPosition = drawRiskAcknowledgments(in: context, with: attributes, yPosition: yPosition)
                
                // Draw aftercare instructions
                yPosition = drawAftercareInstructions(in: context, with: attributes, yPosition: yPosition, pageWidth: pageWidth)
                
                // Draw signatures
                drawSignatures(in: context, with: attributes, yPosition: yPosition)
            }
            
            // Update the form path
            self.formPath = pdfPath
            
            return fileURL
        } catch {
            print("Error generating PDF: \(error)")
            return nil
        }
    }
    
    // MARK: - PDF Helper Methods
    
    /// Prepares the file URL for the PDF
    private func prepareFileURL(forPath path: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Unable to access documents directory")
            return nil
        }
        
        // Create the ConsentForms directory if it doesn't exist
        let formsDirectory = documentsDirectory.appendingPathComponent("ConsentForms", isDirectory: true)
        
        if !fileManager.fileExists(atPath: formsDirectory.path) {
            do {
                try fileManager.createDirectory(at: formsDirectory, withIntermediateDirectories: true)
            } catch {
                print("Error creating ConsentForms directory: \(error)")
                return nil
            }
        }
        
        // Return the PDF file URL
        return documentsDirectory.appendingPathComponent(path)
    }
    
    /// Creates text attributes for drawing
    private func createTextAttributes() -> PDFTextAttributes {
        let titleFont = UIFont.boldSystemFont(ofSize: 18)
        let headerFont = UIFont.boldSystemFont(ofSize: 14)
        let bodyFont = UIFont.systemFont(ofSize: 12)
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]
        
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.black
        ]
        
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: UIColor.black
        ]
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        return PDFTextAttributes(
            title: titleAttributes,
            header: headerAttributes,
            body: bodyAttributes,
            paragraph: paragraphStyle
        )
    }
    
    /// Draws the header (title)
    private func drawHeader(in context: UIGraphicsPDFRendererContext, with attributes: PDFTextAttributes, pageWidth: CGFloat) -> CGFloat {
        let titleString = formTitle ?? "Consent Form"
        let titleStringSize = titleString.size(withAttributes: attributes.title)
        let titleRect = CGRect(x: (pageWidth - titleStringSize.width) / 2, y: 50, width: titleStringSize.width, height: titleStringSize.height)
        titleString.draw(in: titleRect, withAttributes: attributes.title)
        
        return titleRect.maxY + 30
    }
    
    /// Draws client information
    private func drawClientInformation(in context: UIGraphicsPDFRendererContext, with attributes: PDFTextAttributes, yPosition: CGFloat) -> CGFloat {
        var currentYPosition = yPosition
        
        if let client = client {
            let clientHeader = "CLIENT INFORMATION"
            clientHeader.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.header)
            currentYPosition += 25
            
            let clientName = "Name: \(client.fullName)"
            clientName.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
            currentYPosition += 20
            
            if let dob = client.dateOfBirth {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                let dobString = "Date of Birth: \(dateFormatter.string(from: dob))"
                dobString.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
                currentYPosition += 20
            }
            
            if let phone = client.phone, !phone.isEmpty {
                let phoneString = "Phone: \(phone)"
                phoneString.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
                currentYPosition += 20
            }
            
            if let email = client.email, !email.isEmpty {
                let emailString = "Email: \(email)"
                emailString.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
                currentYPosition += 20
            }
            
            if let address = client.formattedAddress, !address.isEmpty {
                let addressString = "Address: \(address)"
                addressString.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
                currentYPosition += 20
            }
            
            if let idNumber = client.idNumber, !idNumber.isEmpty {
                let idString = "ID: \(client.idTypeString) #\(idNumber)"
                idString.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
                currentYPosition += 20
            }
        }
        
        return currentYPosition + 20
    }
    
    /// Draws service information
    private func drawServiceInformation(in context: UIGraphicsPDFRendererContext, with attributes: PDFTextAttributes, yPosition: CGFloat, pageWidth: CGFloat) -> CGFloat {
        var currentYPosition = yPosition
        
        let serviceHeader = "SERVICE INFORMATION"
        serviceHeader.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.header)
        currentYPosition += 25
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let serviceDateString = "Date: \(dateFormatter.string(from: serviceDate ?? Date()))"
        serviceDateString.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
        currentYPosition += 20
        
        let serviceTypeString = "Type: \(formTypeString)"
        serviceTypeString.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
        currentYPosition += 20
        
        let descriptionHeader = "Description:"
        descriptionHeader.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
        currentYPosition += 20
        
        // Draw multiline description
        let descriptionRect = CGRect(x: 50, y: currentYPosition, width: pageWidth - 100, height: 100)
        let descriptionAttributes: [NSAttributedString.Key: Any] = [
            .font: attributes.body[.font] as Any,
            .foregroundColor: attributes.body[.foregroundColor] as Any,
            .paragraphStyle: attributes.paragraph
        ]
        
        let descriptionString = serviceDescription ?? ""
        descriptionString.draw(in: descriptionRect, withAttributes: descriptionAttributes)
        
        return descriptionRect.maxY + 30
    }
    
    /// Draws form type specific details (tattoo or piercing)
    private func drawFormTypeSpecificDetails(in context: UIGraphicsPDFRendererContext, with attributes: PDFTextAttributes, yPosition: CGFloat) -> CGFloat {
        var currentYPosition = yPosition
        
        if formType == 0, let tattooDetails = tattooDetails { // Tattoo
            let detailsHeader = "TATTOO DETAILS"
            detailsHeader.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.header)
            currentYPosition += 25
            
            let locationString = "Location: \(tattooDetails.bodyLocation)"
            locationString.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
            currentYPosition += 20
            
            let designString = "Design: \(tattooDetails.design)"
            designString.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
            currentYPosition += 20
            
            let sizeString = "Size: \(tattooDetails.size)"
            sizeString.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
            currentYPosition += 20
            
            let colorsString = "Colors: \(tattooDetails.colors.joined(separator: ", "))"
            colorsString.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
            currentYPosition += 20
            
            let customString = "Custom Design: \(tattooDetails.isCustom ? "Yes" : "No")"
            customString.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
            currentYPosition += 20
            
            let touchupString = "Includes Touchup: \(tattooDetails.includesTouchup ? "Yes" : "No")"
            touchupString.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
            currentYPosition += 20
            
            if let allergies = tattooDetails.allergies, !allergies.isEmpty {
                let allergiesString = "Allergies: \(allergies)"
                allergiesString.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
                currentYPosition += 20
            }
        } else if formType == 1, let piercingDetails = piercingDetails { // Piercing
            let detailsHeader = "PIERCING DETAILS"
            detailsHeader.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.header)
            currentYPosition += 25
            
            let locationString = "Location: \(piercingDetails.piercingLocation)"
            locationString.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
            currentYPosition += 20
            
            let jewelryTypeString = "Jewelry Type: \(piercingDetails.jewelryType)"
            jewelryTypeString.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
            currentYPosition += 20
            
            let materialString = "Material: \(piercingDetails.jewelryMaterial)"
            materialString.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
            currentYPosition += 20
            
            let gaugeString = "Gauge: \(piercingDetails.jewelryGauge)"
            gaugeString.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
            currentYPosition += 20
            
            if let allergies = piercingDetails.allergies, !allergies.isEmpty {
                let allergiesString = "Allergies: \(allergies)"
                allergiesString.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
                currentYPosition += 20
            }
        }
        
        return currentYPosition + 20
    }
    
    /// Draws risk acknowledgments
    private func drawRiskAcknowledgments(in context: UIGraphicsPDFRendererContext, with attributes: PDFTextAttributes, yPosition: CGFloat) -> CGFloat {
        var currentYPosition = yPosition
        
        let risksHeader = "ACKNOWLEDGMENT OF RISKS"
        risksHeader.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.header)
        currentYPosition += 25
        
        let risks = acknowledgedRisks
        for risk in risks {
            let riskString = "• \(risk)"
            riskString.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
            currentYPosition += 20
        }
        
        if let additionalAcknowledgments = additionalAcknowledgments, !additionalAcknowledgments.isEmpty {
            currentYPosition += 10
            let additionalHeader = "ADDITIONAL ACKNOWLEDGMENTS"
            additionalHeader.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.header)
            currentYPosition += 25
            
            let additionalRect = CGRect(x: 50, y: currentYPosition, width: 500, height: 100)
            
            let additionalAttributes: [NSAttributedString.Key: Any] = [
                .font: attributes.body[.font] as Any,
                .foregroundColor: attributes.body[.foregroundColor] as Any,
                .paragraphStyle: attributes.paragraph
            ]
            
            additionalAcknowledgments.draw(in: additionalRect, withAttributes: additionalAttributes)
            currentYPosition = additionalRect.maxY + 30
        }
        
        return currentYPosition
    }
    
    /// Draws aftercare instructions
    private func drawAftercareInstructions(in context: UIGraphicsPDFRendererContext, with attributes: PDFTextAttributes, yPosition: CGFloat, pageWidth: CGFloat) -> CGFloat {
        var currentYPosition = yPosition
        
        if let aftercare = aftercareInstructions, !aftercare.isEmpty {
            let aftercareHeader = "AFTERCARE INSTRUCTIONS"
            aftercareHeader.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.header)
            currentYPosition += 25
            
            let aftercareRect = CGRect(x: 50, y: currentYPosition, width: pageWidth - 100, height: 100)
            
            let aftercareAttributes: [NSAttributedString.Key: Any] = [
                .font: attributes.body[.font] as Any,
                .foregroundColor: attributes.body[.foregroundColor] as Any,
                .paragraphStyle: attributes.paragraph
            ]
            
            aftercare.draw(in: aftercareRect, withAttributes: aftercareAttributes)
            currentYPosition = aftercareRect.maxY + 30
        }
        
        return currentYPosition
    }
    
    /// Draws signature areas
    private func drawSignatures(in context: UIGraphicsPDFRendererContext, with attributes: PDFTextAttributes, yPosition: CGFloat) {
        var currentYPosition = yPosition + 20
        
        let signaturesHeader = "SIGNATURES"
        signaturesHeader.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.header)
        currentYPosition += 25
        
        // Client signature
        let clientSignatureLabel = "Client Signature:"
        clientSignatureLabel.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
        currentYPosition += 20
        
        // Draw client signature if available
        if let signatures = signatures as? Set<Signature>, !signatures.isEmpty {
            for signature in signatures where signature.signatureType == 0 { // Client signature
                if let signatureImage = signature.loadSignature(), let cgImage = signatureImage.cgImage {
                    let signatureRect = CGRect(x: 50, y: currentYPosition, width: 200, height: 100)
                    context.cgContext.draw(cgImage, in: signatureRect)
                    currentYPosition = signatureRect.maxY + 10
                }
            }
        } else {
            // Draw signature line
            context.cgContext.setStrokeColor(UIColor.black.cgColor)
            context.cgContext.setLineWidth(1.0)
            context.cgContext.move(to: CGPoint(x: 50, y: currentYPosition + 50))
            context.cgContext.addLine(to: CGPoint(x: 250, y: currentYPosition + 50))
            context.cgContext.strokePath()
            currentYPosition += 60
        }
        
        // Artist signature
        let artistSignatureLabel = "Artist Signature:"
        artistSignatureLabel.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
        currentYPosition += 20
        
        // Draw artist signature if available
        if let signatures = signatures as? Set<Signature>, !signatures.isEmpty {
            for signature in signatures where signature.signatureType == 1 { // Artist signature
                if let signatureImage = signature.loadSignature(), let cgImage = signatureImage.cgImage {
                    let signatureRect = CGRect(x: 50, y: currentYPosition, width: 200, height: 100)
                    context.cgContext.draw(cgImage, in: signatureRect)
                    currentYPosition = signatureRect.maxY + 10
                }
            }
        } else {
            // Draw signature line
            context.cgContext.setStrokeColor(UIColor.black.cgColor)
            context.cgContext.setLineWidth(1.0)
            context.cgContext.move(to: CGPoint(x: 50, y: currentYPosition + 50))
            context.cgContext.addLine(to: CGPoint(x: 250, y: currentYPosition + 50))
            context.cgContext.strokePath()
            currentYPosition += 60
        }
        
        // Draw date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = "Date: \(dateFormatter.string(from: Date()))"
        dateString.draw(at: CGPoint(x: 50, y: currentYPosition), withAttributes: attributes.body)
    }
    
    /// Returns all consent forms for a client
    static func fetchConsentFormsForClient(client: Client, in context: NSManagedObjectContext) -> [ConsentForm] {
        let request: NSFetchRequest<ConsentForm> = ConsentForm.fetchRequest()
        request.predicate = NSPredicate(format: "client == %@", client)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ConsentForm.serviceDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching consent forms: \(error)")
            return []
        }
    }
    
    /// Returns all consent forms with the given status
    static func fetchConsentFormsByStatus(status: Int16, in context: NSManagedObjectContext) -> [ConsentForm] {
        let request: NSFetchRequest<ConsentForm> = ConsentForm.fetchRequest()
        request.predicate = NSPredicate(format: "formStatus == %d", status)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ConsentForm.serviceDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching consent forms by status: \(error)")
            return []
        }
    }
    
    /// Returns all consent forms with the given type
    static func fetchConsentFormsByType(type: Int16, in context: NSManagedObjectContext) -> [ConsentForm] {
        let request: NSFetchRequest<ConsentForm> = ConsentForm.fetchRequest()
        request.predicate = NSPredicate(format: "formType == %d", type)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ConsentForm.serviceDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching consent forms by type: \(error)")
            return []
        }
    }
    
    /// Returns all recent consent forms (created in the last 30 days)
    static func fetchRecentConsentForms(in context: NSManagedObjectContext, days: Int = 30) -> [ConsentForm] {
        let request: NSFetchRequest<ConsentForm> = ConsentForm.fetchRequest()
        
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        request.predicate = NSPredicate(format: "createdAt >= %@", thirtyDaysAgo as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ConsentForm.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching recent consent forms: \(error)")
            return []
        }
    }
} 
