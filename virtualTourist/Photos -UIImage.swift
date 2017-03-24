//
//  Photos -UIImage.swift
//  virtualTourist
//
//  Created by Warren Hansen on 11/26/16.
//  Copyright © 2016 Warren Hansen. All rights reserved.
//

import Foundation
import UIKit

extension Photos {
    
    /// Convenience Property to get set the imageDate with a UIImage
    var image : UIImage? {
        get {
            if let imageData = imageData {
                return UIImage(data: imageData as Data)
            }
            return nil
        }
        set(value) {
            if let value = value {
                imageData = UIImageJPEGRepresentation(value, 1) as NSData?
            }
        }
    }
}
