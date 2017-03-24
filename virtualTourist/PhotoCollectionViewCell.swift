//
//  FlickrPhotoCell.swift
//  virtualTourist
//
//  Created by Warren Hansen on 10/19/16.
//  Copyright © 2016 Warren Hansen. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var photoView: UIImageView!
    
    // Outlet for label
    @IBOutlet weak var deleteButton: UIButton!
    
    override func prepareForReuse() {
        
        super.prepareForReuse()
        
        if photoView.image == nil {
            activityIndicator.startAnimating()
        }
    }
}
