//
//  CollectionViewCell.swift
//  FlipCast
//
//  Created by Usman Shahid on 03/08/2015.
//  Copyright (c) 2015 Granjur. All rights reserved.
//

import Foundation

class CollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: PFImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.imageView.contentMode = UIViewContentMode.ScaleAspectFill
        self.imageView.clipsToBounds = true
        
        self.imageView.image = UIImage(named: "user_upload_img.png")
    }
}