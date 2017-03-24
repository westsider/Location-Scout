//
//  Pin.swift
//  virtualTourist
//
//  Created by Warren Hansen on 10/22/16.
//  Copyright © 2016 Warren Hansen. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(Pin)
class Pin: NSManagedObject {
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    init(lat: Double, long: Double, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context)!
        super.init(entity: entity, insertInto: context)
        
        self.latitude = lat
        self.longitude = long
        self.pageNumber = 0
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
        
    }
}
