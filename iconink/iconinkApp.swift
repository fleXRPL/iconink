//
//  iconinkApp.swift
//  iconink
//
//  Created by Garot Conklin on 2/27/25.
//

import SwiftUI

@main
struct IconinkApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
