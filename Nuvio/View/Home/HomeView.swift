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
        })
        .fullScreenCover(isPresented: $createNewCanvas, content: {
            NavigationStack {
                CanvasView(canvas: nil, context: viewContext)
            }
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

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
