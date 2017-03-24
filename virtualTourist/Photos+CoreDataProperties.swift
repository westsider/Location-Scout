//
//  Photos+CoreDataProperties.swift
//  virtualTourist
//
//  Created by Warren Hansen on 10/26/16.
//  Copyright © 2016 Warren Hansen. All rights reserved.
//

import Foundation
import CoreData

extension Photos {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photos> {
        return NSFetchRequest<Photos>(entityName: "Photos");
    }
    
    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var url: String?
    @NSManaged public var pin: Pin?
    @NSManaged var imageData: NSData?
    
}
