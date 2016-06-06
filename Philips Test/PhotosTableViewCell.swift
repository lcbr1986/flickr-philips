//
//  PhotosTableViewCell.swift
//  Philips Test
//
//  Created by Luis Carlos Rosa on 02/06/16.
//  Copyright © 2016 Luís Rosa. All rights reserved.
//

import UIKit

class PhotosTableViewCell: UITableViewCell {
    /// Image to be displayed at the background of the cell
    @IBOutlet weak var photoImageView:UIImageView?
    
    /// The label that displays the title of the photo in the cell
    @IBOutlet weak var photoTitle:UILabel?
    
    /// Height layout constraint for the image view
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    
    /// Top layout constraint for the image view
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = true
        photoImageView?.contentMode = .ScaleAspectFill
        photoImageView?.clipsToBounds = false
    }
    
}
