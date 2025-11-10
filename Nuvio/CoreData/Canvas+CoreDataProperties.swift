//
//  Canvas+CoreDataProperties.swift
//  Nuvio
//
//  Created by Pietro Messineo on 11/10/25.
//

import Foundation
import CoreData

extension Canvas {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Canvas> {
        return NSFetchRequest<Canvas>(entityName: "Canvas")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var createdDate: Date?
    @NSManaged public var modifiedDate: Date?
    @NSManaged public var currentCanvasLayout: Int16 // 0, 1, or 2 for single, dual, triple
    @NSManaged public var thumbnailData: Data?
    
    // Canvas 0 properties
    @NSManaged public var canvas0ContentType: String?
    @NSManaged public var canvas0Notes: String?
    @NSManaged public var canvas0BrowserAddress: String?
    @NSManaged public var canvas0PDFData: Data? // For storing actual PDF document data
    @NSManaged public var canvas0PDFFileName: String? // Original filename for reference
    @NSManaged public var canvas0AIMessages: Data? // JSON encoded AiMessageChunk array
    
    // Canvas 1 properties
    @NSManaged public var canvas1ContentType: String?
    @NSManaged public var canvas1Notes: String?
    @NSManaged public var canvas1BrowserAddress: String?
    @NSManaged public var canvas1PDFData: Data?
    @NSManaged public var canvas1PDFFileName: String?
    @NSManaged public var canvas1AIMessages: Data?
    
    // Canvas 2 properties
    @NSManaged public var canvas2ContentType: String?
    @NSManaged public var canvas2Notes: String?
    @NSManaged public var canvas2BrowserAddress: String?
    @NSManaged public var canvas2PDFData: Data?
    @NSManaged public var canvas2PDFFileName: String?
    @NSManaged public var canvas2AIMessages: Data?

}

// MARK: - Generated accessors for convenience
extension Canvas: Identifiable {
    
}