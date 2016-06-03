//
//  Photo.swift
//  Philips Test
//
//  Created by Luis Carlos Rosa on 31/05/16.
//  Copyright © 2016 Luís Rosa. All rights reserved.
//

import Foundation

/// Flickr Photos
class Photo {
    
    var photoId:String?
    var ownerId:String?
    var secret:String?
    var server:String?
    var farm:Int?
    var title:String?
    var isPublic:Bool?
    var isFriend:Bool?
    var isFamily:Bool?
    
    init(_ dictionary: Dictionary<String, AnyObject>) {
        photoId = dictionary["id"] as? String
        ownerId = dictionary["owner"] as? String
        secret = dictionary["secret"] as? String
        server = dictionary["server"] as? String
        farm = dictionary["farm"] as? Int
        title = dictionary["title"] as? String
        isPublic = dictionary["ispublic"]?.boolValue
        isFriend = dictionary["isfriend"]?.boolValue
        isFamily = dictionary["isfamily"]?.boolValue
    }
    
    convenience init () {
        self.init(Dictionary<String, AnyObject>())
    }
    
    /**
     Returns the generated url for the photo location
     
     - returns: The photo url
     */
    func getImageUrl() -> NSURL {
        return NSURL(string:"https://farm\(farm!).staticflickr.com/\(server!)/\(photoId!)_\(secret!).jpg")!
    }
}
