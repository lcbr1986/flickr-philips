//
//  PhotoDetail.swift
//  Philips Test
//
//  Created by Luis Carlos Rosa on 01/06/16.
//  Copyright © 2016 Luís Rosa. All rights reserved.
//

import Foundation

/// Object with the details of a given photo
class PhotoDetail: Photo {
 
    var dateUploaded:String?
    var owner:[String:AnyObject]?
    var views:Int?
    var description:String?
    
    /**
     Initializer with dictionary
     
     - parameter dictionary: The dictionary with the init data
     
     - returns: The Initialized Photo Detail Object
     */
    override init(_ dictionary: Dictionary<String, AnyObject>) {
        super.init(dictionary)
        self.dateUploaded = dictionary["dateuploaded"] as? String
        self.owner = dictionary["owner"] as? [String:AnyObject]
        self.views = dictionary["views"] as? Int
        self.description = dictionary["description"]?["_content"] as? String
    }
    
    /**
     Initializer with Photo
     
     - parameter photo: The Photo object to init the data
     
     - returns: The Initialized Photo Detail Object
     */
    convenience init(_ photo:Photo) {
        self.init(Dictionary<String, AnyObject>())
        photoId = photo.photoId
        ownerId = photo.ownerId
        secret = photo.secret
        server = photo.server
        farm = photo.farm
        title = photo.title
        isPublic = photo.isPublic
        isFriend = photo.isFriend
        isFamily = photo.isFamily
    }

}