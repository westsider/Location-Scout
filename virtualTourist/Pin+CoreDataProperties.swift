//
//  Pin+CoreDataProperties.swift
//  virtualTourist
//
//  Created by Warren Hansen on 10/26/16.
//  Copyright © 2016 Warren Hansen. All rights reserved.
//

import Foundation
import CoreData

extension Pin {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pin> {
        return NSFetchRequest<Pin>(entityName: "Pin");
    }
    
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var pageNumber: Int32
    @NSManaged public var pinTitle: String?
    @NSManaged public var photos: Photos?
    
}
