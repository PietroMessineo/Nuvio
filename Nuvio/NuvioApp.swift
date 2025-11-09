//
//  NuvioApp.swift
//  Nuvio
//
//  Created by Pietro Messineo on 11/6/25.
//

import SwiftUI
import CoreData
import Piadina

@main
struct NuvioApp: App {
    let persistenceController = PersistenceController.shared
    
    @StateObject var userManager: UserManager = UserManager()
    @StateObject var keychainManager: KeychainManager = KeychainManager()
    @StateObject var chatStreamService: ChatStreamService = ChatStreamService()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                CanvasView()
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .environmentObject(userManager)
            .environmentObject(chatStreamService)
            .task {
                await createUser()
            }
        }
    }
    
    private func createUser() async {
        let userId = keychainManager.userId
        
        if !userId.isEmpty {
            AppData.shared.userToken = userId
            
            do {
                try await userManager.createUser()
            } catch {
                print("Error creating user \(error.localizedDescription)")
            }
        }
    }
}
