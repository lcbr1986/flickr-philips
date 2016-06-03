//
//  PhotoDetailViewController.swift
//  Philips Test
//
//  Created by Luis Carlos Rosa on 02/06/16.
//  Copyright © 2016 Luís Rosa. All rights reserved.
//

import UIKit
import AlamofireImage

class PhotoDetailViewController: UIViewController, UIScrollViewDelegate {
    /// Photo Object
    var photo:PhotoDetail?
    /// The view holding the photo info
    @IBOutlet weak var detailsView:UIView!
    /// The label that holds the date
    @IBOutlet weak var dateLabel:UILabel!
    /// The label with the name of the author
    @IBOutlet weak var ownerLabel:UILabel!
    /// The text field that has the description
    @IBOutlet weak var descriptionLabel:UILabel!
    /// The scroll view where the image will be displayed
    @IBOutlet weak var scrollView:UIScrollView!
    /// The image view where the photo is displayed
    @IBOutlet weak var imageView:UIImageView!
    
    var imageDownloader:ImageDownloader?
    
    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(PhotoDetailViewController.toggleViews))
        tapGesture.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGesture)
        
        imageDownloader = ImageDownloader(
            configuration: ImageDownloader.defaultURLSessionConfiguration(),
            downloadPrioritization: .FIFO,
            maximumActiveDownloads: 6,
            imageCache: AutoPurgingImageCache()
        )
        
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 4.0
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.title = photo?.title
        getPhotoDetail(self.photo!)
    }
    
    // MARK: - API Calls
    
    func getPhotoDetail(photo:PhotoDetail) {
        FlickrAPIManager.sharedManager.getPhotoDetails(photo.photoId!, secret: photo.secret!) { (photoDetail, error) in
            if error != nil {
                //TODO: - Should warn the error
                return
            }
            self.photo = photoDetail
            self.setPhotoInfo(photoDetail)
        }
    }
    
    // MARK: - View Changes
    func toggleViews() {
        UIView.animateWithDuration(0.5) {
            if self.detailsView.alpha == 0 {
                self.detailsView.alpha = 1
                self.toggleNavBar(false)
            } else {
                self.detailsView.alpha = 0
                self.toggleNavBar(true)
            }
        }
    }
    
    // MARK: - NavBar Controls
    
    func toggleNavBar(hidden: Bool) {
        navigationController?.setNavigationBarHidden(hidden, animated: false)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return navigationController?.navigationBarHidden == true
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return UIStatusBarAnimation.Slide
    }
    
    // MARK: - Helpers
    
    func setPhotoInfo(photo: PhotoDetail) {
        let dateUploaded = NSDate(timeIntervalSince1970: Double(photo.dateUploaded!)!)
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy hh:mm"
        self.dateLabel.text = dateFormatter.stringFromDate(dateUploaded)
        self.ownerLabel.text = photo.owner!["realname"] as? String
        if photo.description == "" {
            self.descriptionLabel.alpha = 0;
        } else {
            self.descriptionLabel.text = photo.description
        }
        let URLRequest = NSURLRequest(URL: photo.getImageUrl())
        
        imageDownloader!.downloadImage(URLRequest: URLRequest) { (response) in
            if let image = response.result.value {
                dispatch_async(dispatch_get_main_queue(),{
                    self.imageView.image = image
                })
            }
        }
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
}
