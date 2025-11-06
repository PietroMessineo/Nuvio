//
//  NuvioApp.swift
//  Nuvio
//
//  Created by Pietro Messineo on 11/6/25.
//

import SwiftUI
import CoreData

@main
struct NuvioApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                CanvasView()
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
