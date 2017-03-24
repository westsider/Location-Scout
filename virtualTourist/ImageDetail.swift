//
//  ImageScrollView.swift
//  virtualTourist
//
//  Created by Warren Hansen on 10/27/16.
//  Copyright © 2016 Warren Hansen. All rights reserved.
//

import UIKit

class ImageDetailView: UIViewController {
    
    
    @IBOutlet weak var myImageView: UIImageView!
    
    var selectedImage: String = ""
    var imageData = Data()
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.myImageView.image  = UIImage(data: imageData as Data)
    }
}
