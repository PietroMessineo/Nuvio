//
//  Canvas+CoreDataClass.swift
//  Nuvio
//
//  Created by Pietro Messineo on 11/10/25.
//

import Foundation
import CoreData

@objc(Canvas)
public class Canvas: NSManagedObject {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        // Automatically set UUID and timestamps when creating new Canvas
        if id == nil {
            id = UUID()
        }
        
        if createdDate == nil {
            createdDate = Date()
        }
        
        if modifiedDate == nil {
            modifiedDate = Date()
        }
    }
    
}
