//
//  DataModelConfiguration.swift
//  Nuvio
//
//  Created by Pietro Messineo on 11/10/25.
//

/*
 
 CORE DATA MODEL SETUP INSTRUCTIONS:
 
 You need to add a new Entity called "Canvas" to your Nuvio.xcdatamodeld file with the following attributes:
 
 Entity: Canvas
 
 Attributes:
 - id: UUID (Optional: YES) ← CHANGED: Make this optional to avoid default value requirement
 - title: String (Optional: YES)
 - createdDate: Date (Optional: YES)
 - modifiedDate: Date (Optional: YES)
 - currentCanvasLayout: Integer 16 (Optional: NO, Default: 0)
 - thumbnailData: Binary Data (Optional: YES)
 
 Canvas 0 attributes:
 - canvas0ContentType: String (Optional: YES)
 - canvas0Notes: String (Optional: YES)
 - canvas0BrowserAddress: String (Optional: YES)
 - canvas0PDFBookmark: Binary Data (Optional: YES)
 - canvas0AIMessages: Binary Data (Optional: YES)
 
 Canvas 1 attributes:
 - canvas1ContentType: String (Optional: YES)
 - canvas1Notes: String (Optional: YES)
 - canvas1BrowserAddress: String (Optional: YES)
 - canvas1PDFBookmark: Binary Data (Optional: YES)
 - canvas1AIMessages: Binary Data (Optional: YES)
 
 Canvas 2 attributes:
 - canvas2ContentType: String (Optional: YES)
 - canvas2Notes: String (Optional: YES)
 - canvas2BrowserAddress: String (Optional: YES)
 - canvas2PDFBookmark: Binary Data (Optional: YES)
 - canvas2AIMessages: Binary Data (Optional: YES)
 
 Data Model Settings:
 - Set Codegen to "Manual/None" for the Canvas entity
 - This allows you to use the custom Canvas+CoreDataClass.swift and Canvas+CoreDataProperties.swift files
 
 IMPORTANT: UUID Default Value Fix
 - The id attribute is set as UUID (Optional: YES) to avoid Core Data default value requirements
 - The awakeFromInsert() method in Canvas+CoreDataClass.swift will automatically generate UUIDs
 - This approach is cleaner than setting default values in the Core Data model
 
 After adding the entity:
 1. Select your .xcdatamodeld file
 2. Add a new model version if needed
 3. Set the new version as current if you created one
 4. Make sure Codegen is set to "Manual/None" for Canvas entity
 5. Build your project to ensure everything compiles
 
 */

import Foundation