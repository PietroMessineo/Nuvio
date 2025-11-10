//
//  HomeView.swift
//  Nuvio
//
//  Created by Pietro Messineo on 11/10/25.
//

import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Canvas.modifiedDate, ascending: false)],
        animation: .default)
    private var canvases: FetchedResults<Canvas>
    
    @State private var createNewCanvas: Bool = false
    @State private var selectedCanvas: Canvas? = nil
    
    @Namespace var transition
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let columns = calculateColumns(for: width)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    
                    // New Canvas Card
                    Button {
                        createNewCanvas = true
                    } label: {
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(Color(hex: "F1F1F1"))
                                    .frame(height: 127)
                                
                                VStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .font(.title)
                                        .foregroundStyle(.blue)
                                    Text("New Canvas")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Text("Create New")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                        .frame(width: 181)
                        .matchedTransitionSource(id: "overFullScreenNew", in: transition)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Existing Canvas Cards
                    ForEach(canvases) { canvas in
                        Button {
                            selectedCanvas = canvas
                        } label: {
                            CanvasGridCard(canvas: canvas)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contextMenu {
                            Button("Edit") {
                                selectedCanvas = canvas
                            }
                            
                            Button("Delete", role: .destructive) {
                                deleteCanvas(canvas)
                            }
                        }
                        .matchedTransitionSource(id: "overFullScreen", in: transition)
                    }
                }
                .padding()
            }
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
                    selectedCanvas = nil
                } label: {
                    Image(systemName: "plus")
                        .padding(12)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
            }
            .sharedBackgroundVisibility(.hidden)
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .fullScreenCover(item: $selectedCanvas, content: { selectedCanvas in
            NavigationStack {
                CanvasView(canvas: selectedCanvas, context: viewContext)
            }
            .navigationTransition(.zoom(sourceID: "overFullScreen", in: transition))
        })
        .fullScreenCover(isPresented: $createNewCanvas, content: {
            NavigationStack {
                CanvasView(canvas: nil, context: viewContext)
            }
            .navigationTransition(.zoom(sourceID: "overFullScreenNew", in: transition))
        })
    }
    
    private func deleteCanvas(_ canvas: Canvas) {
        withAnimation {
            viewContext.delete(canvas)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting canvas: \(error)")
            }
        }
    }
    
    private func calculateColumns(for width: CGFloat) -> [GridItem] {
        let itemWidth: CGFloat = 181
        let spacing: CGFloat = 16
        let columnsCount = Int(width / (itemWidth + spacing))
        return Array(repeating: GridItem(.flexible()), count: columnsCount)
    }
}

struct CanvasGridCard: View {
    let canvas: Canvas
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(hex: "F1F1F1"))
                    .frame(height: 127)
                
                VStack(spacing: 8) {
                    // Display icon based on primary canvas content
                    Image(systemName: primaryContentIcon)
                        .font(.title2)
                        .foregroundStyle(primaryContentColor)
                    
                    Text(primaryContentDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Layout indicator
                    HStack(spacing: 2) {
                        ForEach(0...2, id: \.self) { index in
                            Circle()
                                .fill(index <= Int(canvas.currentCanvasLayout) ? .blue : .gray.opacity(0.3))
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(canvas.title ?? "Untitled")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if let date = canvas.modifiedDate {
                    Text(date, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 181)
    }
    
    private var primaryContentIcon: String {
        // Determine primary content based on the current layout
        let currentLayout = Int(canvas.currentCanvasLayout)
        
        if currentLayout >= 0 {
            if let contentType = CanvasContentType(rawValue: canvas.canvas0ContentType ?? "") {
                return iconForContentType(contentType)
            }
        }
        
        return "rectangle"
    }
    
    private var primaryContentColor: Color {
        let currentLayout = Int(canvas.currentCanvasLayout)
        
        if currentLayout >= 0 {
            if let contentType = CanvasContentType(rawValue: canvas.canvas0ContentType ?? "") {
                return colorForContentType(contentType)
            }
        }
        
        return .gray
    }
    
    private var primaryContentDescription: String {
        let currentLayout = Int(canvas.currentCanvasLayout)
        let layoutNames = ["Single", "Dual", "Triple"]
        return layoutNames[min(currentLayout, 2)]
    }
    
    private func iconForContentType(_ type: CanvasContentType) -> String {
        switch type {
        case .empty: return "rectangle"
        case .pdf: return "document"
        case .notes: return "pencil.and.scribble"
        case .browser: return "globe"
        case .ai: return "brain"
        }
    }
    
    private func colorForContentType(_ type: CanvasContentType) -> Color {
        switch type {
        case .empty: return .gray
        case .pdf: return Color(hex: "80C5FB")
        case .notes: return Color(hex: "FBD680")
        case .browser: return Color(hex: "A8D2D1")
        case .ai: return Color(hex: "A080FB")
        }
    }
}

#Preview("HomeView Preview") {
    struct PreviewContainer: View {
        let container: NSPersistentContainer
        init() {
            // Build an in-memory container using the app's model name
            let container = NSPersistentContainer(name: "Nuvio")
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            description.shouldAddStoreAsynchronously = false
            container.persistentStoreDescriptions = [description]

            container.loadPersistentStores { _, error in
                if let error = error {
                    fatalError("Preview store load failed: \(error)")
                }
            }

            // Seed a few Canvas items so the fetch request has entities
            let context = container.viewContext
            for i in 0..<3 {
                let canvas = Canvas(context: context)
                canvas.title = "Canvas \(i + 1)"
                canvas.modifiedDate = Date().addingTimeInterval(Double(-i) * 3600)
                canvas.currentCanvasLayout = Int16(i % 3)
                // Seed primary content type fields referenced by the grid card
                canvas.canvas0ContentType = ["empty", "pdf", "notes", "browser", "ai"][i % 5]
            }
            do { try context.save() } catch { assertionFailure("Failed to seed preview data: \(error)") }

            self.container = container
        }

        var body: some View {
            NavigationStack {
                HomeView()
            }
            .environment(\.managedObjectContext, container.viewContext)
        }
    }

    return PreviewContainer()
}
