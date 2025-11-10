//
//  CanvasDataManager.swift
//  Nuvio
//
//  Created by Pietro Messineo on 11/10/25.
//

import Foundation
import CoreData
import SwiftUI
import Combine

class CanvasDataManager: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    // MARK: - Canvas Management
    
    func createNewCanvas() -> Canvas {
        let newCanvas = Canvas(context: viewContext)
        newCanvas.id = UUID()
        newCanvas.title = "Untitled Canvas"
        newCanvas.createdDate = Date()
        newCanvas.modifiedDate = Date()
        newCanvas.currentCanvasLayout = 0
        
        // Initialize empty canvas data
        initializeCanvasData(newCanvas)
        
        saveContext()
        return newCanvas
    }
    
    private func initializeCanvasData(_ canvas: Canvas) {
        // Initialize all canvases as empty
        canvas.canvas0ContentType = CanvasContentType.empty.rawValue
        canvas.canvas0Notes = ""
        canvas.canvas0BrowserAddress = ""
        
        canvas.canvas1ContentType = CanvasContentType.empty.rawValue
        canvas.canvas1Notes = ""
        canvas.canvas1BrowserAddress = ""
        
        canvas.canvas2ContentType = CanvasContentType.empty.rawValue
        canvas.canvas2Notes = ""
        canvas.canvas2BrowserAddress = ""
    }
    
    func saveCanvasData(canvas: Canvas, canvasData: SavedCanvasData) {
        // Ensure the canvas is in a valid state
        if canvas.isDeleted {
            print("Warning: Attempting to save data to a deleted canvas")
            return
        }
        
        // Force fault resolution by accessing properties
        _ = canvas.title
        
        // Check if it's still a fault after property access
        if canvas.isFault {
            print("Warning: Canvas is still a fault after property access - this may indicate a Core Data issue")
            // Don't return here, try to save anyway as the fault might resolve during save
        }
        
        canvas.modifiedDate = Date()
        canvas.title = canvasData.title
        canvas.currentCanvasLayout = Int16(canvasData.currentCanvas)
        
        // Save Canvas 0 data
        canvas.canvas0ContentType = canvasData.canvas0Data.contentType.rawValue
        canvas.canvas0Notes = canvasData.canvas0Data.notes
        canvas.canvas0BrowserAddress = canvasData.canvas0Data.browserAddress
        canvas.canvas0PDFBookmark = canvasData.canvas0Data.pdfBookmark
        canvas.canvas0AIMessages = encodeAIMessages(canvasData.canvas0Data.messageContent)
        
        // Save Canvas 1 data
        canvas.canvas1ContentType = canvasData.canvas1Data.contentType.rawValue
        canvas.canvas1Notes = canvasData.canvas1Data.notes
        canvas.canvas1BrowserAddress = canvasData.canvas1Data.browserAddress
        canvas.canvas1PDFBookmark = canvasData.canvas1Data.pdfBookmark
        canvas.canvas1AIMessages = encodeAIMessages(canvasData.canvas1Data.messageContent)
        
        // Save Canvas 2 data
        canvas.canvas2ContentType = canvasData.canvas2Data.contentType.rawValue
        canvas.canvas2Notes = canvasData.canvas2Data.notes
        canvas.canvas2BrowserAddress = canvasData.canvas2Data.browserAddress
        canvas.canvas2PDFBookmark = canvasData.canvas2Data.pdfBookmark
        canvas.canvas2AIMessages = encodeAIMessages(canvasData.canvas2Data.messageContent)
        
        saveContext()
    }
    
    func loadCanvasData(from canvas: Canvas) -> SavedCanvasData {        
        let canvas0Data = SavedCanvasData.CanvasData(
            contentType: CanvasContentType(rawValue: canvas.canvas0ContentType ?? "") ?? .empty,
            notes: canvas.canvas0Notes ?? "",
            browserAddress: canvas.canvas0BrowserAddress ?? "",
            pdfBookmark: canvas.canvas0PDFBookmark,
            messageContent: decodeAIMessages(canvas.canvas0AIMessages)
        )
        
        let canvas1Data = SavedCanvasData.CanvasData(
            contentType: CanvasContentType(rawValue: canvas.canvas1ContentType ?? "") ?? .empty,
            notes: canvas.canvas1Notes ?? "",
            browserAddress: canvas.canvas1BrowserAddress ?? "",
            pdfBookmark: canvas.canvas1PDFBookmark,
            messageContent: decodeAIMessages(canvas.canvas1AIMessages)
        )
        
        let canvas2Data = SavedCanvasData.CanvasData(
            contentType: CanvasContentType(rawValue: canvas.canvas2ContentType ?? "") ?? .empty,
            notes: canvas.canvas2Notes ?? "",
            browserAddress: canvas.canvas2BrowserAddress ?? "",
            pdfBookmark: canvas.canvas2PDFBookmark,
            messageContent: decodeAIMessages(canvas.canvas2AIMessages)
        )
        
        return SavedCanvasData(
            title: canvas.title ?? "Untitled Canvas",
            currentCanvas: Int(canvas.currentCanvasLayout),
            canvas0Data: canvas0Data,
            canvas1Data: canvas1Data,
            canvas2Data: canvas2Data
        )
    }
    
    func deleteCanvas(_ canvas: Canvas) {
        viewContext.delete(canvas)
        saveContext()
    }
    
    // MARK: - Helper Methods
    
    /// Ensures a Canvas object is properly loaded and not in a fault state
    func ensureCanvasLoaded(_ canvas: Canvas) -> Canvas? {
        // If deleted, return nil
        if canvas.isDeleted {
            return nil
        }
        
        // Try to access properties to resolve any faults
        do {
            _ = canvas.title
            _ = canvas.id
            
            // If accessing properties worked and it's not a fault, return it
            if !canvas.isFault {
                return canvas
            }
            
            // If it's still a fault, try to refetch it by ID
            if let canvasID = canvas.id {
                let request: NSFetchRequest<Canvas> = Canvas.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", canvasID as CVarArg)
                request.fetchLimit = 1
                
                let results = try viewContext.fetch(request)
                return results.first
            }
        } catch {
            print("Error ensuring canvas is loaded: \(error)")
        }
        
        return nil
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving canvas: \(error)")
        }
    }
    
    private func encodeAIMessages(_ messages: [AiMessageChunk]) -> Data? {
        do {
            return try JSONEncoder().encode(messages)
        } catch {
            print("Error encoding AI messages: \(error)")
            return nil
        }
    }
    
    private func decodeAIMessages(_ data: Data?) -> [AiMessageChunk] {
        guard let data = data else { return [] }
        do {
            return try JSONDecoder().decode([AiMessageChunk].self, from: data)
        } catch {
            print("Error decoding AI messages: \(error)")
            return []
        }
    }
    
    // MARK: - PDF Bookmark Handling
    
    func createPDFBookmark(from url: URL) -> Data? {
        do {
            return try url.bookmarkData(options: .withoutImplicitSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        } catch {
            print("Error creating PDF bookmark: \(error)")
            return nil
        }
    }
    
    func resolvePDFBookmark(_ bookmarkData: Data) -> URL? {
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmarkData, options: .withoutImplicitStartAccessing, relativeTo: nil, bookmarkDataIsStale: &isStale)
            
            if !isStale {
                return url
            }
        } catch {
            print("Error resolving PDF bookmark: \(error)")
        }
        return nil
    }
}

// MARK: - Data Structures

struct SavedCanvasData {
    let title: String
    let currentCanvas: Int
    let canvas0Data: CanvasData
    let canvas1Data: CanvasData
    let canvas2Data: CanvasData
    
    struct CanvasData {
        let contentType: CanvasContentType
        let notes: String
        let browserAddress: String
        let pdfBookmark: Data?
        let messageContent: [AiMessageChunk]
    }
}
