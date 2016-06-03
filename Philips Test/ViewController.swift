//
//  ViewController.swift
//  Philips Test
//
//  Created by Luis Carlos Rosa on 31/05/16.
//  Copyright © 2016 Luís Rosa. All rights reserved.
//

import UIKit
import AlamofireImage

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    /// The array that stores the photos
    var photos:[Photo] = [Photo]()
    /// The current search page
    var currentPage:Int!
    /// Total number of pages in the search
    var totalPages:Int!
    /// The table view that displays the photo list
    @IBOutlet weak var tableView: UITableView!
    /// Refresh controll for the table view
    var refreshControl: UIRefreshControl!
    /// Label to inform the user to search for a term
    @IBOutlet weak var searchPhotosLabel: UILabel!
    /// The image downloader
    var imageDownloader:ImageDownloader?
    /// The search term to search
    var searchTerm:String?
    
    // http://stackoverflow.com/questions/31373775/how-do-i-create-a-parallax-effect-in-uitableview-with-uiimageview-in-their-proto
    var cellHeight: CGFloat {
        return tableView.frame.width * 9 / 16
    }
    var imageVisibleHeight: CGFloat {
        return cellHeight
    }
    let parallaxOffsetSpeed: CGFloat = 25
    var parallaxImageHeight: CGFloat {
        let maxOffset = (sqrt(pow(cellHeight, 2) + 4 * parallaxOffsetSpeed * tableView.frame.height) - cellHeight) / 2
        return imageVisibleHeight + maxOffset
    }
    
    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: NSLocalizedString("Pull to refresh", comment: ""))
        refreshControl.addTarget(self, action: #selector(ViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)

        imageDownloader = ImageDownloader(
            configuration: ImageDownloader.defaultURLSessionConfiguration(),
            downloadPrioritization: .FIFO,
            maximumActiveDownloads: 6,
            imageCache: AutoPurgingImageCache()
        )
        setInitialValue()
        self.searchPhotosLabel.text = NSLocalizedString("Please insert a search term to filter the photos", comment: "")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        imageDownloader = nil
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.title = NSLocalizedString("Flickr Search", comment: "")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.title = ""
    }
    /**
     Resets the values for the search
     */
    func setInitialValue() {
        self.currentPage = 1
        self.totalPages = 0
        self.photos = [Photo]()
    }

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetailSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            guard let photo:Photo = photos[indexPath!.row] else {
                fatalError("Application error no cell data available")
            }
            let photoDetailViewController = segue.destinationViewController as! PhotoDetailViewController
            photoDetailViewController.photo = PhotoDetail(photo)
        }
    }
    
    // MARK: - API Calls
    /**
     Asks the API Manager to get the search results
     
     - parameter searchTerm: The search term to filter
     - parameter page: The search page
     */
    func getSearchResults(searchTerm: String, page: Int) {
        FlickrAPIManager.sharedManager.getSearchResults(searchTerm, page: page) { (photos, totalPages, error) in
            self.refreshControl.endRefreshing()
            if error != nil {
                let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: error?.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: { 
                    if self.photos.count == 0 {
                        self.searchPhotosLabel.alpha = 1
                    }
                })                    
                return
            }
            self.totalPages = totalPages
            self.photos.appendContentsOf(photos)
            if self.photos.count == 0 {
                self.searchPhotosLabel.alpha = 1
            } else {
                self.searchPhotosLabel.alpha = 0
            }
            self.tableView.reloadData()
        }
    }
    
    // MARK: - UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.currentPage < self.totalPages {
            return photos.count + 1
        }
        return photos.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if self.currentPage < self.totalPages && indexPath.row == self.photos.count {
            let cell = tableView.dequeueReusableCellWithIdentifier("loadingCell", forIndexPath: indexPath) as! PhotosTableViewCell
            return cell
        }
        guard let photo:Photo = photos[indexPath.row] else {
            fatalError("Application error no cell data available")
        }
        let cell:PhotosTableViewCell = tableView.dequeueReusableCellWithIdentifier("photoCell", forIndexPath: indexPath) as! PhotosTableViewCell
        cell.photoImageView?.image = UIImage()
        cell.imageViewHeightConstraint.constant = parallaxImageHeight
        cell.photoTitle?.text = photo.title
        let URLRequest = NSURLRequest(URL: photo.getImageUrl())
        imageDownloader?.downloadImage(URLRequest: URLRequest) { (response) in
            if let image = response.result.value {
                dispatch_async(dispatch_get_main_queue(),{
                    cell.photoImageView?.image = image
                })
            }
        }
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if self.currentPage < self.totalPages && indexPath.row == photos.count {
            self.currentPage = self.currentPage + 1
            getSearchResults(self.searchTerm!, page: self.currentPage)
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offsetY = tableView.contentOffset.y
        for cell in (tableView.visibleCells as? [PhotosTableViewCell])! {
            if (cell.imageViewTopConstraint != nil) {
                cell.imageViewTopConstraint.constant = parallaxOffsetFor(offsetY, cell: cell)
            }
        }
    }
    
    func parallaxOffsetFor(newOffsetY: CGFloat, cell: UITableViewCell) -> CGFloat {
        return ((newOffsetY - cell.frame.origin.y) / parallaxImageHeight) * parallaxOffsetSpeed
    }
    
    // MARK: - Refresh
    
    func refresh(sender:AnyObject) {
        setInitialValue()
        getSearchResults(self.searchTerm!, page: self.currentPage)
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        if searchBar.text == "" {
            self.searchPhotosLabel.alpha = 1
        } else {
            setInitialValue()
            self.tableView.reloadData()
            self.searchTerm = searchBar.text!
            getSearchResults(self.searchTerm!, page: self.currentPage)
        }
    }
}

