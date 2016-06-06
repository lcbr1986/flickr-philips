//
//  FlickrAPIManager.swift
//  Philips Test
//
//  Created by Luis Carlos Rosa on 31/05/16.
//  Copyright © 2016 Luís Rosa. All rights reserved.
//

import Foundation
import Alamofire

/// The Shared intance of the Flickr API Manager
private let sharedManager = FlickrAPIManager()

/// Manages The Api calls to the Flickr Service
class FlickrAPIManager {
    
    static let sharedManager = FlickrAPIManager()
    
    private init () {
        
    }
    
    /**
     Gets the search result from the server and Parses the data
     
     - parameter searchTerm: The term to search
     - parameter page:       Page number
     - parameter completion: Completion closure with the parsed Photos, total pages and error
     */
    func getSearchResults(searchTerm:String, page:Int, completion:(photos:[Photo], totalPages:Int, error:NSError?) -> Void){
        Alamofire.request(FlickrAPIRouter.SearchPhotos(searchTerm: searchTerm, page: page)).validate().responseJSON() { (response) in
            guard response.result.isSuccess else {
                print("Error getting the photos: \(response.result.error)")
                completion(photos:[Photo](), totalPages: 0, error: response.result.error!)
                return
            }
            guard let responseJson = response.result.value as? [String: AnyObject],
                results = responseJson["photos"] as? [String: AnyObject],
                totalPages = results["pages"] as? Int,
                photos = results["photo"] as? [[String: AnyObject]] else {
                    print("Invalid results")
                    completion(photos: [Photo](), totalPages: 0, error: NSError(domain: "MyDomain", code: -99, userInfo: [NSLocalizedDescriptionKey: "Invalid results"]))
                    return
            }
            var parsedPhotos = [Photo]()
            for photo: [String: AnyObject] in photos {
                let parsedPhoto = Photo(photo)
                parsedPhotos.append(parsedPhoto)
            }
            completion(photos:parsedPhotos, totalPages: totalPages, error:nil)
        }
    }
    
    /**
     Gets a more detailed info about the photo
     
     - parameter photoId:    The id of the photo
     - parameter secret:     The secret of the photo
     - parameter completion: Completion closure with the parsed Photo and error
     */
    func getPhotoDetails(photoId:String, secret:String, completion:(photoDetail: PhotoDetail, error:NSError?) -> Void) {
        Alamofire.request(FlickrAPIRouter.GetPhotoDetail(photoId: photoId, secret: secret)).validate().responseJSON { (response) in
            guard response.result.isSuccess else {
                print("Error getting the photos: \(response.result.error)")
                completion(photoDetail:PhotoDetail(), error: response.result.error!)
                return
            }
            guard let responseJson = response.result.value as? [String: AnyObject],
                photoInfo = responseJson["photo"] as? [String: AnyObject] else {
                print("Invalid results")
                completion(photoDetail: PhotoDetail(), error: NSError(domain: "MyDomain", code: -99, userInfo: [NSLocalizedDescriptionKey: "Invalid results"]))
                return
            }
            let photoDetail = PhotoDetail(photoInfo)
            completion(photoDetail: photoDetail, error: nil)
        }
    }
}

/// An enum that Routs the requests to the API calls
public enum FlickrAPIRouter: URLRequestConvertible {
    static let dict = NSDictionary(contentsOfFile: NSBundle.mainBundle().pathForResource("Flickr", ofType: "plist")!) as? [String: AnyObject]    
    
    static let baseURLPath = dict!["BaseUrl"] as! String
    static let apiKey = dict!["APIKey"] as! String
    
    case SearchPhotos(searchTerm:String, page:Int)
    case GetPhotoDetail(photoId:String, secret:String)
    
    public var URLRequest: NSMutableURLRequest {
        //nojsoncallback required to parse the response correctly
        //http://stackoverflow.com/questions/15930932/how-do-i-parse-this-flickr-response
        var parameters: [String: AnyObject] = ["api_key": FlickrAPIRouter.apiKey, "format": "json", "nojsoncallback": 1]
        
        let result: (path: String, method: Alamofire.Method, parameters: [String: AnyObject]) = {
            switch self {
            case .SearchPhotos(let searchTerm, let page):
                parameters["method"] = "flickr.photos.search"
                parameters["text"] = searchTerm
                parameters["page"] = page
                return ("", .GET, parameters)
            case .GetPhotoDetail(let photoId, let secret):
                parameters["method"] = "flickr.photos.getInfo"
                parameters["photo_id"] = photoId
                parameters["secret"] = secret
                return ("", .GET, parameters)
            }
        }()
        let URL = NSURL(string: FlickrAPIRouter.baseURLPath)!
        let URLRequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent(result.path))
        URLRequest.HTTPMethod = result.method.rawValue
        URLRequest.timeoutInterval = NSTimeInterval(10 * 1000)
        let enconding = Alamofire.ParameterEncoding.URL        
        
        return enconding.encode(URLRequest, parameters: result.parameters).0
    }
    
}