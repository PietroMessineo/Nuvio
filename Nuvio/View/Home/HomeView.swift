//
//  HomeView.swift
//  Nuvio
//
//  Created by Pietro Messineo on 11/10/25.
//

import SwiftUI
import CoreData

struct HomeView: View {
    var body: some View {
        VStack {
            // TODO: - Sections for subjects grid layout 181 x 127 and 22 of radius
        }
        .toolbar(content: {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    // TODO: - Open Settings
                } label: {
                    Image(systemName: "gearshape")
                }
            }
            
            ToolbarItem(placement: .principal) {
                Button {
                    // TODO: - Open Flashcards
                } label: {
                    HStack {
                        Image(systemName: "checkmark.rectangle.stack")
                        
                        Text("Flashcards")
                            .fontWeight(.medium)
                    }
                    .padding(12)
                    .glassEffect(.regular.interactive(), in: .capsule)
                }
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    // TODO: Import something
                } label: {
                    Text("Import")
                        .fontWeight(.medium)
                        .padding(12)
                        .glassEffect(.regular.interactive(), in: .capsule)
                }
            }
            .sharedBackgroundVisibility(.hidden)
            
            ToolbarSpacer(.flexible)
            
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // TODO: - Open New Canvas
                } label: {
                    Image(systemName: "plus")
                        .padding(12)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
            }
            .sharedBackgroundVisibility(.hidden)
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
