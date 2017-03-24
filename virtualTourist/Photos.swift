//
//  Photos.swift
//  virtualTourist
//
//  Created by Warren Hansen on 10/26/16.
//  Copyright © 2016 Warren Hansen. All rights reserved.

import Foundation
import CoreData
import UIKit


@objc(Photos)
class Photos: NSManagedObject {
    
    // MARK: - Init model
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    init(photoURL: String, pin: Pin, context: NSManagedObjectContext){
        
        let entity = NSEntityDescription.entity(forEntityName: "Photos", in: context)!
        super.init(entity: entity, insertInto: context)
        self.url = photoURL
        self.pin = pin
        //print("init from Photos.swift\(url)")
        
    }
}
