//
//  LandingPage.swift
//  FlipCast
//
//  Created by Usman Shahid on 08/06/2015.
//  Copyright (c) 2015 Granjur. All rights reserved.
//

import UIKit
import Parse
import AVFoundation
import Photos

class LandingPage: UIViewController, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, UISearchBarDelegate, AdobeUXImageEditorViewControllerDelegate, ImageEditor_Delegare, UICollectionViewDataSource, UICollectionViewDelegate  {
    
    var refreshControl:UIRefreshControl!
    let textCellIdentifier = "LandingTableCell"
    let picker = UIImagePickerController()
    
    var animateView: Bool = false
    var isViewTransformed: Bool = false
    
    var postsObjects : NSMutableArray = NSMutableArray()
    var featuredPosts : NSMutableArray = NSMutableArray()
    var searchObjects: NSMutableArray = NSMutableArray()
    var userObjects  : NSMutableArray = NSMutableArray()
    var searchActive : Bool!
    var imageEditorVC : ImageEditor!
    var showStatusBar: Bool!
    var isLoadingMore: Bool!
    
    var FULL_BTN: UIButton!
    
    var editor : AdobeUXImageEditorViewController!
    var isPost : Bool!
    var isCamera : Bool!
    var cellIndex : Int!
    let SHARE_ACTION_SHEET_TAG = 10
    var sharing_postCard = UIImage()
    var chosenImage: UIImage!
    
    // MARK: - OUTLETS
    
    @IBOutlet weak var loadingFooter: UIView!
    
    @IBOutlet weak var featuredPostLabel: UILabel!
    @IBOutlet weak var myCollectionView: UICollectionView!
    @IBOutlet weak var mySearchBar: UISearchBar!
    @IBOutlet weak var bgScrollView: UIImageView!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var selectPictureView: UIView!
    
    // MARK: - BUTTON ACTIONS
    
    @IBAction func hidePictureSelectionView(sender: AnyObject) {
        self.selectPictureView.hidden = true
        isPost = false
        
        self.mySearchBar.resignFirstResponder()
        self.searchActive = false
    }
    @IBAction func galarySelectClicked(sender: AnyObject) {
        
        self.mySearchBar.resignFirstResponder()
        self.searchActive = false
        
        isCamera = false
        isPost = true
        PHPhotoLibrary.requestAuthorization
            { (PHAuthorizationStatus status) -> Void in
                switch (status)
                {
                case .Authorized:
                    // Permission Granted
                    self.picker.allowsEditing = false
                    self.picker.sourceType = .PhotoLibrary
                    self.presentViewController(self.picker, animated: true, completion: nil)
                case .Denied:
                    // Permission Denied
                    self.presentViewController(HELPER.showAlertWithMessage("Permission", alertMessage: "You havn't granted permission to use photo library", buttonTitle: "Ok"), animated: false, completion: nil)
                    return
                default:
                    println ("no galary")
                }
        }
        
        if AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) ==  AVAuthorizationStatus.Authorized   {
            // Already Authorized
        }
        else    {
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
                if granted == true  {
                    // User granted
                    self.picker.allowsEditing = false
                    self.picker.sourceType = .PhotoLibrary
                    self.presentViewController(self.picker, animated: true, completion: nil)
                }
                else    {
                    // User Rejected
                    self.presentViewController(HELPER.showAlertWithMessage("Permission", alertMessage: "You havn't granted permission to use camera", buttonTitle: "Ok"), animated: false, completion: nil)
                }
            });
        }
    }
    @IBAction func cameraSelectClicked(sender: AnyObject) {
        self.mySearchBar.resignFirstResponder()
        self.searchActive = false
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)){
            isCamera = true
            isPost = true
            
            if AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) ==  AVAuthorizationStatus.Authorized
            {
                
                self.showStatusBar = false
//                self.setNeedsStatusBarAppearanceUpdate()
//                self.prefersStatusBarHidden()
                // Already Authorized
                self.picker.allowsEditing = false
                self.picker.sourceType = .Camera
                self.presentViewController(picker, animated: true, completion: nil)
            }
            else
            {
                AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
                    if granted == true
                    {
                        // User granted
                        self.picker.allowsEditing = false
                        self.picker.sourceType = .Camera
                        
                        
                        
                        
                        self.presentViewController(self.picker, animated: true, completion: nil)
                    }
                    else
                    {
                        // User Rejected
                        self.presentViewController(HELPER.showAlertWithMessage("Permission", alertMessage: "You havn't granted permission to use camera", buttonTitle: "Ok"), animated: true, completion: nil)
                    }
                });
            }
        }
        else{
            self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: "Camera Error", buttonTitle: "Ok"), animated: true, completion: nil)
        }
    }
    @IBAction func createFlipClicked(sender: AnyObject) {
        self.mySearchBar.resignFirstResponder()
        self.searchActive = false
        self.selectPictureView.hidden = false
        
    }
    @IBAction func categoriesClicked(sender: AnyObject) {
        self.mySearchBar.resignFirstResponder()
        self.searchActive = false
    }
    
    @IBAction func sideMenuClicked(sender: AnyObject) {
        
        self.mySearchBar.resignFirstResponder()
        self.searchActive = false
        
        // We need to move back to the normal view by clicking at Menu Button (ELSE part)
        if (!isViewTransformed) {
            
            NOTIFY.removeObserver(self)
            NOTIFY.postNotificationName(ADJUST_OVERLAY_ALPHA, object: nil)
            
            FULL_BTN.hidden = false
            
            UIView.animateWithDuration(0.75, delay: 0.0, options: UIViewAnimationOptions.TransitionNone, animations: {
                var t: CATransform3D = CATransform3DIdentity
                t.m34 = (-1.0/500.0)
                t = CATransform3DRotate(t, self.degree2radian(-45.0), 0, 1, 0);
                t = CATransform3DTranslate(t, self.view.bounds.size.width*0.3, 0, -self.view.bounds.size.width*0.8);
                self.view.layer.transform = t;
                }, completion: { finished in
                    println("View Moved :)")
                    self.isViewTransformed = true
            })
        }
        else    {
            FULL_BTN.hidden = true
            self.isViewTransformed = false
            NOTIFY.postNotificationName(SLIDE_VIEW_LEFT, object: nil)
            NOTIFY.addObserver(self, selector: "reloadTableView:", name:RELOAD_POSTS, object: nil)
            NOTIFY.addObserver(self, selector: "cellButtonsClicked:", name:NOTIF_CELL_IMAGE_BUTTON_CLICKED, object: nil)
            
            var t: CATransform3D = CATransform3DIdentity
            t.m34 = (-1.0/500.0)
            t = CATransform3DRotate(t, self.degree2radian(-45.0), 0, 1, 0);
            t = CATransform3DTranslate(t, self.view.bounds.size.width*0.3, 0, -self.view.bounds.size.width*0.8);
            self.view.layer.transform = t;
            
            UIView.animateWithDuration(0.75, delay: 0.0, options: UIViewAnimationOptions.TransitionNone, animations: {
                var t: CATransform3D = CATransform3DIdentity
                t = CATransform3DRotate(t, self.degree2radian(0.0), 0, 1, 0);
                t = CATransform3DTranslate(t, 0.0, 0, 0.0);
                self.view.layer.transform = t;
                }, completion: { finished in
                    println("View Moved :)")
                    self.isViewTransformed = false
            })
        }
    }
    
    
    @IBAction func logOutClicked(sender: AnyObject) {
        
    }
    
    // MARK: - DEFAULTS
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.isLoadingMore = false
        self.showStatusBar = true
        self.loadingFooter.hidden = true
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
        
        searchActive = false
        
        self.selectPictureView.hidden = true
        cellIndex = 0
        isPost = false
        
        NOTIFY.addObserver(self, selector: "reloadTableView:", name:RELOAD_POSTS, object: nil)
        NOTIFY.addObserver(self, selector: "cellButtonsClicked:", name:NOTIF_CELL_IMAGE_BUTTON_CLICKED, object: nil)
        
        self.myCollectionView.delegate = self
        self.myCollectionView.dataSource = self
        self.myCollectionView!.registerClass(PFCollectionViewCell.self, forCellWithReuseIdentifier: "PFCollectionViewCell")
        self.myCollectionView.tag = 11
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        // Image picker
        self.picker.delegate = self
        
        // Searchbar
        let uiButton = self.mySearchBar.valueForKey("cancelButton") as! UIButton
        self.mySearchBar.setShowsCancelButton(false, animated: false)

        var textFieldInsideSearchBar = self.mySearchBar.valueForKey("searchField") as? UITextField
        
        textFieldInsideSearchBar?.textColor = UIColor.whiteColor()
        textFieldInsideSearchBar?.enablesReturnKeyAutomatically = false
//        textFieldInsideSearchBar?.clearButtonMode = UITextFieldViewModeAlways
        self.mySearchBar.delegate = self
        
        HELPER.showActivityIndicatory(self.view)
        loadFeaturedPosts()
        loadData(kMAX_POST_LIMIT, skip: self.postsObjects.count)
        
        if (animateView)    {
            var t: CATransform3D = CATransform3DIdentity
            t.m34 = (-1.0/500.0)
            t = CATransform3DRotate(t, self.degree2radian(-45.0), 0, 1, 0);
            t = CATransform3DTranslate(t, self.view.bounds.size.width*0.3, 0, -self.view.bounds.size.width*0.8);
            self.view.layer.transform = t;
            
            UIView.animateWithDuration(0.75, delay: 0.0, options: UIViewAnimationOptions.TransitionNone, animations: {
                var t: CATransform3D = CATransform3DIdentity
                t = CATransform3DRotate(t, self.degree2radian(0.0), 0, 1, 0);
                t = CATransform3DTranslate(t, 0.0, 0, 0.0);
                self.view.layer.transform = t;
                }, completion: { finished in
                    println("View Moved :)")
            })
        }
        
        FULL_BTN = UIButton(frame: self.view.frame)
        FULL_BTN.addTarget(self, action: "sideMenuClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        FULL_BTN.hidden = true
        self.view.addSubview(FULL_BTN)
        self.view.bringSubviewToFront(FULL_BTN)
        
    }
    
    deinit {
        NOTIFY.removeObserver(self)
    }
    
    func degree2radian(a:CGFloat)->CGFloat {
        let b = CGFloat(M_PI) * a/180
        return b
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        
        NSLog("HIDE = %@", !self.showStatusBar)
        UIApplication.sharedApplication().setStatusBarHidden(!self.showStatusBar, withAnimation: UIStatusBarAnimation.None)
        return !self.showStatusBar
    }
    
    // MARK: - CUSTOM ACTIONS
    
    func refresh() {
        
        if (self.isLoadingMore == true) {
            return
        }
        
        if (self.isLoadingMore == false)    {
            self.isLoadingMore = true
        }
        
        HELPER.showActivityIndicatory(self.view)
        
        if (self.searchActive == true)  {
            self.searchObjects.removeAllObjects()
            searchUsers(kMAX_POST_LIMIT, skip: self.searchObjects.count)
        }
        else    {
            self.postsObjects.removeAllObjects()
            loadData(kMAX_POST_LIMIT, skip: self.postsObjects.count)
        }
    }
    
    func loadFeaturedPosts() {
        
        var query = PFQuery(className:_FEATURED_POSTS)
        query.includeKey(_OWNER)
        query.orderByDescending(_CREATED_AT)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                // The find succeeded.
                println("Successfully retrieved \(objects!.count).")
                // Do something with the found objects
                if let objects = objects as? [PFObject] {
                    for object in objects {
                        println("ID = \(object.objectId)")
                        var obj: PostsObject = PostsObject(dict: object) as PostsObject
                        self.featuredPosts.addObject(obj)
                    }
                    self.myCollectionView.reloadData()
                }
            } else {
                let errorString = error!.userInfo?["error"] as? NSString
                // SHOW ERROR
                self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: errorString?.description, buttonTitle: "Ok"), animated: true, completion: nil)
            }
        }
    }
    
    func loadData(var limit: Int, var skip: Int) {
        
        self.loadingFooter.hidden = false
        var query = PFQuery(className:_POSTS)
        query.includeKey(_OWNER)
        query.orderByDescending(_CREATED_AT)
        query.limit = limit
        query.skip = skip
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                // The find succeeded.
                println("Successfully retrieved \(objects!.count).")
                
                self.isLoadingMore = false
                // Do something with the found objects
                if let objects = objects as? [PFObject] {
                    for object in objects {
                        println("ID = \(object.objectId)")
                        var obj: PostsObject = PostsObject(dict: object) as PostsObject
                        self.postsObjects.addObject(obj)
                    }
                    self.refreshControl.endRefreshing()
                    self.loadingFooter.hidden = true
                    self.tableView.reloadData()
//                    self.loadFlips()
                }
                HELPER.stopActivityIndicator(self.view)
            } else {
                
                self.isLoadingMore = false
                // Hide activity indicator
                self.loadingFooter.hidden = true
                HELPER.stopActivityIndicator(self.view)
                self.refreshControl.endRefreshing()
                
                let errorString = error!.userInfo?["error"] as? NSString
                // SHOW ERROR
                self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: errorString?.description, buttonTitle: "Ok"), animated: true, completion: nil)
            }
        }
    }
    
    func searchUsers(var limit: Int, var skip: Int) {
        if (self.mySearchBar.text.isEmpty == false) {
            var query = PFUser.query()
            query!.whereKey(_CASE_INSEN_FN, containsString: self.mySearchBar.text.lowercaseString)
            query!.findObjectsInBackgroundWithBlock {
                (objects: [AnyObject]?, error: NSError?) -> Void in
                
                if error == nil {
                    // The find succeeded.
                    //                    println("Successfully retrieved \(objects!.count).")
                    // Do something with the found objects
                    if let objects = objects as? [PFObject] {
                        for object in objects {
                            self.userObjects.addObject(object)
                        }
                        self.isLoadingMore = false
                        if (self.userObjects.count > 0)   {
                            NSLog("self.userObjects.count = %d", self.userObjects.count)
                            self.searchData(kMAX_POST_LIMIT, skip: self.searchObjects.count)
                        }
                        else    {
                            HELPER.stopActivityIndicator(self.view)
                            self.tableView.reloadData()
                        }
                    }
                } else {
                    HELPER.stopActivityIndicator(self.view)
                    let errorString = error!.userInfo?["error"] as? NSString
                    self.tableView.reloadData()
                    // SHOW ERROR
                }
            }
        }
        else    {
            HELPER.stopActivityIndicator(self.view)
            self.tableView.reloadData()
        }
    }
    func searchData(var limit: Int, var skip: Int) {
        self.loadingFooter.hidden = false
        if (self.userObjects.count > 0) {
            var flips_Edited_array: NSMutableArray = NSMutableArray()
            NSLog("self.userObjects.count = %d", self.userObjects.count)
            
            var query_find_flips_user_edited = PFQuery(className:_FLIPS)
            query_find_flips_user_edited.includeKey(_OWNER)
            query_find_flips_user_edited.whereKey(_OWNER, containedIn: self.userObjects as [AnyObject])
            query_find_flips_user_edited.findObjectsInBackgroundWithBlock {
                (objects: [AnyObject]?, error: NSError?) -> Void in
                
                if error == nil {
                    // The find succeeded.
                    println("Successfully retrieved \(objects!.count).")
                    self.isLoadingMore = false
                    // Do something with the found objects
                    if let objects = objects as? [PFObject] {
                        for object in objects {
                            println("FlipsID = \(object.objectId)")
                            if let parent_post_id: String = object[_PARENT_ID] as? String   {
                                flips_Edited_array.addObject(parent_post_id)
                            }
                        }
                        self.searchPosts(flips_Edited_array, limit: limit, skip: skip)
                    }
                } else {
                    // Hide activity indicator
                    self.isLoadingMore = false
                    HELPER.stopActivityIndicator(self.view)
                    self.tableView.reloadData()
                    
                    let errorString = error!.userInfo?["error"] as? NSString
                    // SHOW ERROR
                    self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: errorString?.description, buttonTitle: "Ok"), animated: true, completion: nil)
                }
            }
        }
        else    {
            HELPER.stopActivityIndicator(self.view)
            self.tableView.reloadData()
        }
    }
    
    func searchPosts(var array: NSMutableArray, var limit: Int, var skip: Int)   {
        // Find user's created POSTS
        if (self.userObjects.count > 0) {
            var query_find_user = PFQuery(className:_POSTS)
            query_find_user.whereKey(_OWNER, containedIn: self.userObjects as [AnyObject])
            
            var query_find_flips_user_edited = PFQuery(className:_POSTS)
            query_find_flips_user_edited.whereKey(_OBJECT_ID, containedIn: array as [AnyObject])
            
            
            var query = PFQuery.orQueryWithSubqueries([query_find_user, query_find_flips_user_edited])
            query.includeKey(_OWNER)
            query.orderByDescending(_CREATED_AT)
            query.limit = limit
            query.skip = skip
            
            query.findObjectsInBackgroundWithBlock {
                (objects: [AnyObject]?, error: NSError?) -> Void in
                
                if error == nil {
                    // The find succeeded.
                    println("Successfully retrieved \(objects!.count).")
                    // Do something with the found objects
                    if let objects = objects as? [PFObject] {
                        for object in objects {
                            var obj: PostsObject = PostsObject(dict: object) as PostsObject
                            self.searchObjects.addObject(obj)
                        }
                        self.refreshControl.endRefreshing()
                        self.loadingFooter.hidden = true
                        self.tableView.reloadData()
                        
                        //                    self.loadFlips()
                    }
                    HELPER.stopActivityIndicator(self.view)
                } else {
                    // Hide activity indicator
                    self.refreshControl.endRefreshing()
                    HELPER.stopActivityIndicator(self.view)
                    
                    let errorString = error!.userInfo?["error"] as? NSString
                    // SHOW ERROR
                    self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: errorString?.description, buttonTitle: "Ok"), animated: true, completion: nil)
                }
            }
        }
        else    {
            HELPER.stopActivityIndicator(self.view)
            self.tableView.reloadData()
        }
    }
    
    // MARK: - CUSTOM IMAGE EDITOR DELEGATE
    func imageSelected(selectedImg: UIImage, hasEditedWithPost: Bool) {
        isCamera = false
        if (isPost == true) {
            var imageData: NSData!
            if (hasEditedWithPost == true)  {
                imageData = UIImageJPEGRepresentation(chosenImage, 1)
            }
            else    {
                imageData = UIImageJPEGRepresentation(selectedImg, 1)
            }
            
            HELPER.showActivityIndicatory(self.view)
            let imageFile:PFFile = PFFile(data: imageData)
            
            var flipObject          = PFObject(className:_POSTS)
//            flipObject[_IS_PRIVATE] = false
            flipObject[_OWNER]      = PFUser.currentUser()
            flipObject[_IMAGE]      = imageFile
            
            flipObject.saveInBackgroundWithBlock {
                (success: Bool, error: NSError?) -> Void in
                if (success) {
                    if (hasEditedWithPost == false)  {
                        HELPER.stopActivityIndicator(self.view)
                        
                    }
                    if (self.searchActive == true)  {
                        self.searchObjects.insertObject(PostsObject(dict: flipObject), atIndex: 0)
                    }
                    
                    self.postsObjects.insertObject(PostsObject(dict: flipObject), atIndex: 0)
                    self.tableView.reloadData()
                    
                    if (hasEditedWithPost == true)  {
                        let imageData = UIImageJPEGRepresentation(selectedImg, 1)
                        let imageFile:PFFile = PFFile(data: imageData)
                        
                        var myObject: PostsObject
                        if (self.searchActive == true)  {
                            myObject = self.searchObjects.objectAtIndex(0) as! PostsObject
                        }
                        else    {
                            myObject = self.postsObjects.objectAtIndex(0) as! PostsObject
                        }
                        
                        
                        var flipObject          = PFObject(className:_FLIPS)
                        //            flipObject[_IS_PRIVATE] = false
                        flipObject[_OWNER]      = PFUser.currentUser()
                        flipObject[_EDITOR]     = PFUser.currentUser()
                        flipObject[_PARENT_ID]  = myObject.postId
                        flipObject[_IMAGE]      = imageFile
                        
                        var obj:FlipsObject = FlipsObject(dict: flipObject)
                        myObject.flips.insertObject(obj, atIndex: 0)
                        
                        flipObject.saveInBackgroundWithBlock {
                            (success: Bool, error: NSError?) -> Void in
                            if (success) {
                                HELPER.stopActivityIndicator(self.view)
                                self.tableView.reloadData()
                            } else {
                                HELPER.stopActivityIndicator(self.view)
                                let errorString = error!.userInfo?["error"] as? NSString
                                // SHOW ERROR
                                self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: errorString?.description, buttonTitle: "Ok"), animated: true, completion: nil)
                            }
                        }
                        
                        var query = PFQuery(className:_POSTS)
                        query.getObjectInBackgroundWithId(myObject.postId) {
                            (obbj: PFObject?, error: NSError?) -> Void in
                            if error != nil {
                                println(error)
                            } else  {
                                obbj?.setValue(false, forKey: "isPrivate")
                                obbj!.saveInBackground()
                            }
                        }
                    }
                    
                } else {
                    HELPER.stopActivityIndicator(self.view)
                    let errorString = error!.userInfo?["error"] as? NSString
                    // SHOW ERROR
                    self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: errorString?.description, buttonTitle: "Ok"), animated: true, completion: nil)
                }
            }
            isPost = false
            self.selectPictureView.hidden = true
            
            
        }
        else    {
            let imageData = UIImageJPEGRepresentation(selectedImg, 1)
            HELPER.showActivityIndicatory(self.view)
            let imageFile:PFFile = PFFile(data: imageData)
            
            var myObject: PostsObject
            if (self.searchActive == true)  {
                myObject = self.searchObjects.objectAtIndex(cellIndex) as! PostsObject
            }
            else    {
                myObject = self.postsObjects.objectAtIndex(cellIndex) as! PostsObject
            }
            
            var flipObject          = PFObject(className:_FLIPS)
//            flipObject[_IS_PRIVATE] = false
            flipObject[_OWNER]      = PFUser.currentUser()
            flipObject[_EDITOR]     = PFUser.currentUser()
            flipObject[_PARENT_ID]  = myObject.postId
            flipObject[_IMAGE]      = imageFile
            
            var obj:FlipsObject = FlipsObject(dict: flipObject)
            myObject.flips.insertObject(obj, atIndex: 0)
            
            flipObject.saveInBackgroundWithBlock {
                (success: Bool, error: NSError?) -> Void in
                if (success) {
                    HELPER.stopActivityIndicator(self.view)
                    self.tableView.reloadData()
                } else {
                    HELPER.stopActivityIndicator(self.view)
                    let errorString = error!.userInfo?["error"] as? NSString
                    // SHOW ERROR
                    self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: errorString?.description, buttonTitle: "Ok"), animated: true, completion: nil)
                }
            }
            
            var query = PFQuery(className:_POSTS)
            query.getObjectInBackgroundWithId(myObject.postId) {
                (obbj: PFObject?, error: NSError?) -> Void in
                if error != nil {
                    println(error)
                } else  {
                    obbj?.setValue(false, forKey: "isPrivate")
                    obbj!.saveInBackground()
                }
            }
            
            isPost = false
        }
    }
    func retakePic()    {
        if (isPost == true) {
            if (isCamera == true)   {
                cameraSelectClicked(UIButton())
            }
            else    {
                galarySelectClicked(UIButton())
            }
        }
    }
    // MARK: - PHOTO EDITOR DELEGATE
    func photoEditor(photoEditor: AdobeUXImageEditorViewController, finishedWithImage image: UIImage) {
       if (isPost == true) {
            let imageData = UIImageJPEGRepresentation(image, 1)
            HELPER.showActivityIndicatory(self.view)
            let imageFile:PFFile = PFFile(data: imageData)
            
            var flipObject          = PFObject(className:_POSTS)
//            flipObject[_IS_PRIVATE] = false
            flipObject[_OWNER]      = PFUser.currentUser()
            flipObject[_IMAGE]      = imageFile
        
            flipObject.saveInBackgroundWithBlock {
                (success: Bool, error: NSError?) -> Void in
                if (success) {
                    HELPER.stopActivityIndicator(self.view)
                    self.postsObjects.insertObject(PostsObject(dict: flipObject), atIndex: 0)
                    self.tableView.reloadData()
                } else {
                    HELPER.stopActivityIndicator(self.view)
                    let errorString = error!.userInfo?["error"] as? NSString
                    // SHOW ERROR
                    self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: errorString?.description, buttonTitle: "Ok"), animated: true, completion: nil)
                }
            }
            isPost = false
            self.selectPictureView.hidden = true
            
        }
        else    {
            let imageData = UIImageJPEGRepresentation(image, 1)
            HELPER.showActivityIndicatory(self.view)
            let imageFile:PFFile = PFFile(data: imageData)
            
            var myObject: PostsObject = self.postsObjects.objectAtIndex(cellIndex) as! PostsObject
            
            var flipObject          = PFObject(className:_FLIPS)
//            flipObject[_IS_PRIVATE] = false
            flipObject[_OWNER]      = PFUser.currentUser()
            flipObject[_EDITOR]     = PFUser.currentUser()
            flipObject[_PARENT_ID]  = myObject.postId
            flipObject[_IMAGE]      = imageFile
            
            var obj:FlipsObject = FlipsObject(dict: flipObject)
            myObject.flips.insertObject(obj, atIndex: 0)
            
            flipObject.saveInBackgroundWithBlock {
                (success: Bool, error: NSError?) -> Void in
                if (success) {
                    HELPER.stopActivityIndicator(self.view)
                    self.tableView.reloadData()
                } else {
                    HELPER.stopActivityIndicator(self.view)
                    let errorString = error!.userInfo?["error"] as? NSString
                    // SHOW ERROR
                    self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: errorString?.description, buttonTitle: "Ok"), animated: true, completion: nil)
                }
            }
            isPost = false
            photoEditor .dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func savedImageAlert()
    {
        var alert:UIAlertView = UIAlertView()
        alert.title = "Saved!"
        alert.message = "Your picture was saved to Camera Roll"
        alert.delegate = self
        alert.addButtonWithTitle("Ok")
        alert.show()
    }
    
    func photoEditorCanceled(photoEditor: AdobeUXImageEditorViewController) {
        photoEditor .dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - SCROLL VIEW DELEGATES
    
    func scrollViewDidScroll(scrollView: UIScrollView)  {
        
    }
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if (scrollView.tag != 10)   {
            let currentOffset = scrollView.contentOffset.y
            let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
            if ( (maximumOffset - currentOffset) <= 0) {
                NSLog("LoadMore")
                if (self.isLoadingMore == false)    {
                    self.isLoadingMore = true
                    if (self.searchActive == true)  {
                        searchUsers(kMAX_POST_LIMIT, skip: self.searchObjects.count)
                    }
                    else    {
                        loadData(kMAX_POST_LIMIT, skip: self.postsObjects.count)
                    }
                }
//                loadSegment(items.count, size: PageSize)
            }
        }
        var index = Int(self.myCollectionView.contentOffset.x/self.myCollectionView.frame.size.width)
        if (self.featuredPosts.count > 0)  {
            var myObject: PostsObject = self.featuredPosts.objectAtIndex(index) as! PostsObject
            if (DeviceType.IS_IPHONE_6)   {
                if let font = UIFont(name: "Lato-Black", size: 17.0*1.17) {
                    featuredPostLabel.attributedText = NSAttributedString(string: String(format: "By %@", myObject.owner.fullName), attributes: [NSFontAttributeName: font, NSStrokeColorAttributeName : UIColor.whiteColor(),
                        NSStrokeWidthAttributeName : -3.0, NSForegroundColorAttributeName:UIColor.darkGrayColor()])
                }
            }
            if (DeviceType.IS_IPHONE_6P)   {
                if let font = UIFont(name: "Lato-Black", size: 17.0*1.3) {
                    featuredPostLabel.attributedText = NSAttributedString(string: String(format: "By %@", myObject.owner.fullName), attributes: [NSFontAttributeName: font, NSStrokeColorAttributeName : UIColor.whiteColor(),
                        NSStrokeWidthAttributeName : -3.0, NSForegroundColorAttributeName:UIColor.darkGrayColor()])
                }
            }
            else    {
                if let font = UIFont(name: "Lato-Black", size: 17.0) {
                    featuredPostLabel.attributedText = NSAttributedString(string: String(format: "By %@", myObject.owner.fullName), attributes: [NSFontAttributeName: font, NSStrokeColorAttributeName : UIColor.whiteColor(),
                        NSStrokeWidthAttributeName : -3.0, NSForegroundColorAttributeName:UIColor.darkGrayColor()])
                }
            }
        }
    }
    
    // MARK: - TABLVIEW DELEGATES
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(self.searchActive == true) {
            return searchObjects.count
        }
        else    {
            return postsObjects.count;
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell: LandingTableCell = tableView.dequeueReusableCellWithIdentifier("LandingTableCell", forIndexPath: indexPath) as! LandingTableCell

        // Default images
        cell.profilePicView.image = UIImage(named: "user_upload_img.png")
        
        
        var myObject: PostsObject
        // Load profile pic
        if (self.searchActive == true)  {
            myObject = self.searchObjects.objectAtIndex(indexPath.row) as! PostsObject
        }
        else    {
            myObject = self.postsObjects.objectAtIndex(indexPath.row) as! PostsObject
        }
        
        var count: Int = myObject.flips.count - 2
        if (count == 1)  {
            cell.flipsText.text = String(format: "+%d other", count)
        }
        else if (count > 2)  {
            cell.flipsText.text = String(format: "+%d others", count)
        }
        else    {
            cell.flipsText.text = " "
        }
        
        // Make Tags so that they speak there position, let say tag is
        // 11 -> 11/10 = 1 (row Index), 11%10 = 1 (Image1)
        cell.profilePicView.tag = 10*indexPath.row+kPROFILE_TAG
        cell.likeButton.tag = 10*indexPath.row+kLIKES_TAG
        cell.profilePic.tag = 10*indexPath.row+kPROFILE_TAG
        cell.shareButton.tag = 10*indexPath.row+kSHARE_TAG
        //        cell.flippedImg1.tag = 10*indexPath.row+kIMG_FLIP1_TAG
        cell.refreshButton.tag = 10*indexPath.row+kREFRESH_TAG
        cell.myCollectionView.tag = 10*indexPath.row+kIMG_FLIP1_TAG
        cell.favoritiesButton.tag = 10*indexPath.row+kFAVORITES_TAG
        var indexPath: NSIndexPath = NSIndexPath(forItem: Int(0), inSection: 0)
        
        cell.orignal_Image_file = myObject.image
        cell.myCollectionView.reloadData()
        
        cell.flipsArray = myObject.flips
        // CHANGED BY CLIENT -> Only show name of owner
        /*
        if (myObject.flips.count > 0)   {
            var flippedObj: FlipsObject = myObject.flips.objectAtIndex(0) as! FlipsObject
            if (flippedObj.flipper.fullName != nil)    {
                
                cell.profilePicView.file = flippedObj.flipper.image       // This is for FLIPPER
                
                cell.profilePicView.loadInBackground({ (image : UIImage?, error: NSError?) -> Void in
                    if (error == nil)   {
                        cell.profilePicView.image = image
                        cell.profilePicView.viewWithTag(100)?.removeFromSuperview()
                    }
                })
            }
        }
        else {*/
            cell.profilePicView.file = myObject.owner.image
            cell.profilePicView.loadInBackground()
//        ({ (image : UIImage?, error: NSError?) -> Void in
//                if (error == nil)   {
//                    cell.profilePicView.image = image
//                    cell.profilePicView.viewWithTag(100)?.removeFromSuperview()
//                }
//            })
//        }
        
        if ((myObject.createdAt) != nil) {
            var currentDate: NSDate = NSDate()
            cell.timeElapsed.text = SHARED.getDateDifferenceString(currentDate, earlierDate: myObject.createdAt!)
        }
        
        // CHANGED BY CLIENT -> Only show name of owner
        /*
        if (myObject.flips.count > 0)   {
            var flippedObj: FlipsObject = myObject.flips.objectAtIndex(0) as! FlipsObject
            if (flippedObj.flipper.fullName != nil)    {
                
                cell.nameText.text = flippedObj.flipper.fullName
            }
        }
        else*/ if ((myObject.owner.fullName) != nil) {
            cell.nameText.text = myObject.owner.fullName
        }
        
        if (myObject.postId != nil) {
            cell.flipObjID = myObject.postId
        }
        
        if (myObject.likes != nil)   {
            cell.likesCount.text = String(myObject.likes.count)
        }
        
        return cell

    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println("You selected cell #\(indexPath.row)!")
    }

    // MARK: - IMAGE PICKER DELEGATE
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject])    {
            self.showStatusBar = true
            UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
//            self.setNeedsStatusBarAppearanceUpdate()
//            self.prefersStatusBarHidden()
        
            self.dismissViewControllerAnimated(false, completion: { () -> Void in
//            var chosenImage = info[UIImagePickerControllerEditedImage] as! UIImage
            
            if let img: UIImage = (info[UIImagePickerControllerEditedImage]) as? UIImage {
                self.chosenImage = info[UIImagePickerControllerEditedImage] as! UIImage
            }
            else    {
                self.chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            }
            self.imageEditorVC = self.storyboard!.instantiateViewControllerWithIdentifier("ImageEditor") as! ImageEditor
            self.imageEditorVC.imageToBeEdited       = self.chosenImage
            self.imageEditorVC.imageToBePresented    = self.chosenImage
            self.imageEditorVC.delegate = self
            self.imageEditorVC.postObj = nil
            self.imageEditorVC.creationMode = true
            self.imageEditorVC.notifMode = false
            self.imageEditorVC.indexLocation = NSIndexPath(forItem: 0, inSection: 0)
            
//            UIView.transitionWithView(self.view, duration: 1.0, options: UIViewAnimationOptions.TransitionFlipFromLeft, animations: {
                self.view.addSubview(self.imageEditorVC.view)
                self.view.bringSubviewToFront(self.imageEditorVC.view)
                if (self.isPost == true) {
                    self.imageEditorVC.postButton.setTitle("Post", forState: UIControlState.Normal)
                }
                
//                }, completion: { (fininshed: Bool) -> () in
//            })
        })
        
        
    }
    func imagePickerControllerDidCancel(picker: UIImagePickerController)   {
        self.showStatusBar = true
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
//        self.setNeedsStatusBarAppearanceUpdate()
//        self.prefersStatusBarHidden()
        dismissViewControllerAnimated(false, completion: nil)
        isPost = false
    }
    
    // MARK: - ACTION SHEET DELEGATE
    // Called when a button is clicked. The view will be automatically dismissed after this call returns
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        
    }
    
    // Avoid presenting controller when action sheet is already dismissing
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int)   { // after animation
        if (actionSheet.tag == SHARE_ACTION_SHEET_TAG)  {
            // FACEBOOK
            if (buttonIndex == 1) {
                APP_DELEGATE.shareFBPhoto(sharing_postCard)
            }
            // EMAIL
            if (buttonIndex == 2) {
                APP_DELEGATE.sendEmail_Image(SHARE_TEXT, image: sharing_postCard)
            }
            // SMS
            if (buttonIndex == 3) {
                APP_DELEGATE.sendMessage_Image(SHARE_TEXT, image: sharing_postCard)
            }
        }
        else    {
            // GALARY
            if (buttonIndex == 1) {
                
                PHPhotoLibrary.requestAuthorization
                    { (PHAuthorizationStatus status) -> Void in
                        switch (status)
                        {
                        case .Authorized:
                            // Permission Granted
                            self.picker.allowsEditing = false
                            self.picker.sourceType = .PhotoLibrary
                            self.presentViewController(self.picker, animated: true, completion: nil)
                        case .Denied:
                            // Permission Denied
                            self.presentViewController(HELPER.showAlertWithMessage("Permission", alertMessage: "You havn't granted permission to use photo library", buttonTitle: "Ok"), animated: true, completion: nil)
                        default:
                            self.presentViewController(HELPER.showAlertWithMessage("Permission", alertMessage: "You havn't granted permission to use photo library", buttonTitle: "Ok"), animated: true, completion: nil)
                        }
                }
                
                if AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) ==  AVAuthorizationStatus.Authorized   {
                    // Already Authorized
                }
                else    {
                    AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
                        if granted == true  {
                            // User granted
                            self.picker.allowsEditing = false
                            self.picker.sourceType = .PhotoLibrary
                            self.presentViewController(self.picker, animated: true, completion: nil)
                        }
                        else    {
                            // User Rejected
                            self.presentViewController(HELPER.showAlertWithMessage("Permission", alertMessage: "You havn't granted permission to use camera", buttonTitle: "Ok"), animated: true, completion: nil)
                        }
                    });
                }
            }
            // CAMERA
            if (buttonIndex == 2) {
                
                if AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) ==  AVAuthorizationStatus.Authorized
                {
                    // Already Authorized
                    self.picker.allowsEditing = false
                    self.picker.sourceType = .Camera
                    self.presentViewController(picker, animated: true, completion: nil)
                }
                else
                {
                    AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
                        if granted == true
                        {
                            // User granted
                            self.picker.allowsEditing = false
                            self.picker.sourceType = .Camera
                            self.presentViewController(self.picker, animated: true, completion: nil)
                        }
                        else
                        {
                            // User Rejected
                            self.presentViewController(HELPER.showAlertWithMessage("Permission", alertMessage: "You havn't granted permission to use camera", buttonTitle: "Ok"), animated: true, completion: nil)
                        }
                    });
                }
            }
        }
    }
    // Called when we cancel a view (eg. the user clicks the Home button). This is not called when the user clicks the cancel button.
    // If not defined in the delegate, we simulate a click in the cancel button
    func actionSheetCancel(actionSheet: UIActionSheet)  {
        
    }

    // MARK: - SEARCH BAR DELEGATE
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        self.mySearchBar.becomeFirstResponder()
        self.mySearchBar.setShowsCancelButton(true, animated: false)
        let uiButton = self.mySearchBar.valueForKey("cancelButton") as! UIButton
        uiButton.setTitleColor(UIColor.yellowColor(), forState: UIControlState.Normal)
        
//        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        self.mySearchBar.resignFirstResponder()
        if (searchBar.text.isEmpty == true) {
            self.mySearchBar.setShowsCancelButton(false, animated: false)
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        self.mySearchBar.resignFirstResponder()
        self.searchActive = false
        self.mySearchBar.text = ""
        self.tableView.reloadData()
//        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchActive = true;
        self.searchObjects.removeAllObjects()
        self.mySearchBar.text = searchBar.text
        self.mySearchBar.resignFirstResponder()
        if (searchBar.text.isEmpty == true)  {
            self.mySearchBar.setShowsCancelButton(false, animated: false)
            self.searchActive = false
            self.tableView.reloadData()
            return
        }
        HELPER.showActivityIndicatory(self.view)
        searchUsers(kMAX_POST_LIMIT, skip: self.searchObjects.count)
        
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
//        self.mySearchBar.resignFirstResponder()
//        self.searchActive = false
    }
    
    // MARK: - COLLECTION VIEW
    
    // MARK: - CollectionView data source
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int   {
        return self.featuredPosts.count
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PFCollectionViewCell", forIndexPath: indexPath) as! PFCollectionViewCell
        //        if (indexPath.row > 0)  {
        // Load profile pic
        cell.imageView.image = UIImage(named: "featured.png")
        cell.imageView.clipsToBounds = true
        cell.imageView.contentMode = UIViewContentMode.ScaleAspectFit
        if (self.featuredPosts.count > 0)  {
            var myObject: PostsObject = self.featuredPosts.objectAtIndex(indexPath.row) as! PostsObject
            cell.imageView.file = myObject.image
            cell.imageView.loadInBackground()
            
            
            if (DeviceType.IS_IPHONE_6)   {
                if let font = UIFont(name: "Lato-Black", size: 17.0*1.17) {
                    featuredPostLabel.attributedText = NSAttributedString(string: String(format: "By %@", myObject.owner.fullName), attributes: [NSFontAttributeName: font, NSStrokeColorAttributeName : UIColor.whiteColor(),
                        NSStrokeWidthAttributeName : -3.0, NSForegroundColorAttributeName:UIColor.darkGrayColor()])
                }
            }
            if (DeviceType.IS_IPHONE_6P)   {
                if let font = UIFont(name: "Lato-Black", size: 17.0*1.3) {
                    featuredPostLabel.attributedText = NSAttributedString(string: String(format: "By %@", myObject.owner.fullName), attributes: [NSFontAttributeName: font, NSStrokeColorAttributeName : UIColor.whiteColor(),
                        NSStrokeWidthAttributeName : -3.0, NSForegroundColorAttributeName:UIColor.darkGrayColor()])
                }
            }
            else    {
                if let font = UIFont(name: "Lato-Black", size: 17.0) {
                    featuredPostLabel.attributedText = NSAttributedString(string: String(format: "By %@", myObject.owner.fullName), attributes: [NSFontAttributeName: font, NSStrokeColorAttributeName : UIColor.whiteColor(),
                        NSStrokeWidthAttributeName : -3.0, NSForegroundColorAttributeName:UIColor.darkGrayColor()])
                }
            }
            
            
        }
        return cell;
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int  {
        return 1
    }

    
    // MARK: - CollectionView delegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)  {
        NOTIFY.removeObserver(self)
        println("kPROFILE_TAG")
        var myObject: PostsObject = self.featuredPosts.objectAtIndex(indexPath.row) as! PostsObject
        if (myObject.flips != nil)  {
            if (myObject.flips.count > 0)  {
                var flippedObj: FlipsObject = myObject.flips.objectAtIndex(0) as! FlipsObject
                NOTIFY.postNotificationName(NOTIF_SHOW_USER_PROFILE, object: nil, userInfo:["user" : flippedObj.getFlipper()])
            }
            else    {
                NOTIFY.postNotificationName(NOTIF_SHOW_USER_PROFILE, object: nil, userInfo:["user" : myObject.getOwner()])
            }
        }
        else    {
            NOTIFY.postNotificationName(NOTIF_SHOW_USER_PROFILE, object: nil, userInfo:["user" : myObject.getOwner()])
        }
        return;
    }

    
    // MARK: - NOTIFICATIONS
    
    func reloadTableView(notification: NSNotification){
        
        self.tableView.reloadData()
    }

    func cellButtonsClicked(notification: NSNotification){
        
        var tag: Int = notification.userInfo!["tag"] as! Int
        
        NSLog("TAG = %d, rowIndex = %d, actualTag = %d", tag, Int(tag/10), Int(tag%10))
        cellIndex = Int(tag/10)
        var indexPath: NSIndexPath = NSIndexPath(forItem: Int(tag/10), inSection: 0)
        
        if let cell: LandingTableCell = (self.tableView.cellForRowAtIndexPath(indexPath) as? LandingTableCell)   {
        
            switch  (Int(tag%10)) {
                case kIMG_FLIP1_TAG:
                        imageEditorVC = storyboard!.instantiateViewControllerWithIdentifier("ImageEditor") as! ImageEditor
                        imageEditorVC.imageToBeEdited       = cell.orignal_Image
                        self.imageEditorVC.delegate = self
                        var col_cell_indexPath: NSIndexPath = notification.userInfo!["indexPath"] as! NSIndexPath
                        var flipsArray = notification.userInfo!["flipsArray"] as! NSMutableArray
                        imageEditorVC.flipsArray = flipsArray
                        if (self.searchActive == true)  {
                            imageEditorVC.postObj = self.searchObjects.objectAtIndex(cellIndex) as! PostsObject
                        }
                        else    {
                            imageEditorVC.postObj = self.postsObjects.objectAtIndex(cellIndex) as! PostsObject
                        }
                        imageEditorVC.indexLocation = col_cell_indexPath
                        imageEditorVC.notifMode = false
                        imageEditorVC.creationMode = false
                        
                        if let cell_col: PFCollectionViewCell = (cell.myCollectionView.cellForItemAtIndexPath(col_cell_indexPath) as? PFCollectionViewCell)   {
                            imageEditorVC.imageToBePresented    = cell_col.imageView.image
                        }
                        
                        
//                        UIView.transitionWithView(self.view, duration: 1.0, options: UIViewAnimationOptions.TransitionFlipFromLeft, animations: {
                            self.view.addSubview(self.imageEditorVC.view)
                            self.view.bringSubviewToFront(self.imageEditorVC.view)
                
//                            }, completion: { (fininshed: Bool) -> () in
//                        })
                
//                        UIView.transitionWithView(self.view, duration: 1.0, options: transitionOptions, animations: { () -> Void in
//                            //code
//                            self.view.addSubview(views.frontView)
//                        }, completion: { (Bool) -> Void in
//                            //code
//                            self.view.addSubview(views.frontView)
//                        })
//                        transitionWithView(self.view, duration: 1.0, options: transitionOptions, animations: {
//                            // remove the front object...
////                            views.frontView.removeFromSuperview()
//                            
//                            // ... and add the other object
//                            self.view.addSubview(views.frontView)
//                            
//                            }, completion: { finished in
//                                // any code entered here will be applied
//                                // .once the animation has completed
//                        })
                        
                        
                
//                }
                case kIMG_FLIP2_TAG:
                    imageEditorVC = storyboard!.instantiateViewControllerWithIdentifier("ImageEditor") as! ImageEditor
                    self.view.addSubview(imageEditorVC.view)
                    self.view.bringSubviewToFront(imageEditorVC.view)
                    imageEditorVC.fullScreenImage.image = cell.flippedImg2.backgroundImageForState(UIControlState.Normal)
                case kIMG_FLIP3_TAG:
                    imageEditorVC = storyboard!.instantiateViewControllerWithIdentifier("ImageEditor") as! ImageEditor
                    self.view.addSubview(imageEditorVC.view)
                    self.view.bringSubviewToFront(imageEditorVC.view)
                    imageEditorVC.fullScreenImage.image = cell.flippedImg3.backgroundImageForState(UIControlState.Normal)
                case kFAVORITES_TAG:
                    println("kFAVORITES_TAG")
                    var myObject: PostsObject
                    if (self.searchActive == true)  {
                        myObject = self.searchObjects.objectAtIndex(indexPath.row) as! PostsObject
                    }
                    else    {
                        myObject = self.postsObjects.objectAtIndex(indexPath.row) as! PostsObject
                    }
                    if (myObject.postId == cell.flipObjID)  {
                        println("YES")
                        if ( !(myObject.favourities.containsObject(PFUser.currentUser()!.objectId!)) )  {
                            myObject.favourities.addObject(PFUser.currentUser()!.objectId!)
                            
                            var query = PFQuery(className:_POSTS)
                            query.includeKey(_OWNER)
                            query.whereKey(_OBJECT_ID, equalTo: cell.flipObjID)
                            query.findObjectsInBackgroundWithBlock {
                                (objects: [AnyObject]?, error: NSError?) -> Void in
                                
                                if error == nil {
                                    // The find succeeded.
                                    println("Successfully retrieved \(objects!.count).")
                                    // Do something with the found objects
                                    if let objects = objects as? [PFObject] {
                                        for flipObject in objects {
                                            //                                            println("ID = \(flipObject.objectId)")
                                            
                                            flipObject[_FAVOURITIES] = myObject.favourities
                                            flipObject.saveInBackgroundWithBlock {
                                                (success: Bool, error: NSError?) -> Void in
                                                if (success) {
                                                    //                                                self.tableView.reloadData()
                                                } else {
                                                    let errorString = error!.userInfo?["error"] as? NSString
                                                    // SHOW ERROR
                                                    self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: errorString?.description, buttonTitle: "Ok"), animated: true, completion: nil)
                                                }
                                            }
                                            
                                        }
                                    }
                                } else {
                                    
                                    let errorString = error!.userInfo?["error"] as? NSString
                                    // SHOW ERROR
                                    self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: errorString?.description, buttonTitle: "Ok"), animated: true, completion: nil)
                                }
                            }
                        }
                        else {
                            self.presentViewController(HELPER.showAlertWithMessage("It is already in your favourites list", alertMessage: "", buttonTitle: "Ok"), animated: true, completion: nil)
                        }
                    }
                case kLIKES_TAG:
                    println("kLIKES_TAG")
                    var myObject: PostsObject
                    if (self.searchActive == true)  {
                        myObject = self.searchObjects.objectAtIndex(indexPath.row) as! PostsObject
                    }
                    else    {
                        myObject = self.postsObjects.objectAtIndex(indexPath.row) as! PostsObject
                    }
                    if (myObject.postId == cell.flipObjID)  {
                        println("YES")
                        if ( !(myObject.likes.containsObject(PFUser.currentUser()!.objectId!)) )  {
                            myObject.likes.addObject(PFUser.currentUser()!.objectId!)
                            
                            var query = PFQuery(className:_POSTS)
                            query.includeKey(_OWNER)
                            query.whereKey(_OBJECT_ID, equalTo: cell.flipObjID)
                            query.findObjectsInBackgroundWithBlock {
                                (objects: [AnyObject]?, error: NSError?) -> Void in
                                
                                if error == nil {
                                    // The find succeeded.
                                    println("Successfully retrieved \(objects!.count).")
                                    // Do something with the found objects
                                    if let objects = objects as? [PFObject] {
                                        for flipObject in objects {
//                                            println("ID = \(flipObject.objectId)")
                                            
                                            flipObject[_LIKES] = myObject.likes
                                            flipObject.saveInBackgroundWithBlock {
                                                (success: Bool, error: NSError?) -> Void in
                                                if (success) {
    //                                                self.tableView.reloadData()
                                                } else {
                                                    let errorString = error!.userInfo?["error"] as? NSString
                                                    // SHOW ERROR
                                                    self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: errorString?.description, buttonTitle: "Ok"), animated: true, completion: nil)
                                                }
                                            }

                                        }
                                    }
                                } else {
                                    
                                    let errorString = error!.userInfo?["error"] as? NSString
                                    // SHOW ERROR
                                    self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: errorString?.description, buttonTitle: "Ok"), animated: true, completion: nil)
                                }
                            }
                        }
                        else {
                            self.presentViewController(HELPER.showAlertWithMessage("You have already liked this post", alertMessage: "", buttonTitle: "Ok"), animated: true, completion: nil)
                        }
                    }
                
                case kSHARE_TAG:    
                    println("kSHARE_TAG")
                    var myObject: PostsObject = self.postsObjects.objectAtIndex(indexPath.row) as! PostsObject
                    cell.nameText.text = myObject.owner.fullName
                    cell.profilePicView.file = myObject.owner.image
                    cell.profilePicView.loadInBackground()
                    let layer = cell.layer
                    let scale = UIScreen.mainScreen().scale
                    UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
                    
                    layer.renderInContext(UIGraphicsGetCurrentContext())
                    let screenshot = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    self.tableView.reloadData()
                    var actionSheet = UIActionSheet(title: "Choose a Sharing Method", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Facebook", "Email", "SMS")
                    actionSheet.tag = SHARE_ACTION_SHEET_TAG
                    sharing_postCard = screenshot //notification.userInfo!["shareImg"] as! UIImage
                    actionSheet.showInView(self.view)
                
                case kREFRESH_TAG:
                
                
                    // FLOW CHANGED BY CLIENT
//                    if let cell_col: PFCollectionViewCell = (cell.myCollectionView.cellForItemAtIndexPath(NSIndexPath(forItem: Int(0), inSection: 0)) as? PFCollectionViewCell)   {
//                        editor = AdobeUXImageEditorViewController(image: cell_col.imageView.image)
//                        editor.delegate = self
//                    }
//                    
//                    self.presentViewController(editor, animated: true, completion: nil)
                
                    imageEditorVC = storyboard!.instantiateViewControllerWithIdentifier("ImageEditor") as! ImageEditor
                    imageEditorVC.imageToBeEdited       = cell.orignal_Image
                    imageEditorVC.creationMode = true
                    self.imageEditorVC.delegate = self
                    var col_cell_indexPath: NSIndexPath = NSIndexPath(forItem: 0, inSection: 0)
                    imageEditorVC.flipsArray = nil
                    if (self.searchActive == true)  {
                        imageEditorVC.postObj = self.searchObjects.objectAtIndex(cellIndex) as! PostsObject
                    }
                    else    {
                        imageEditorVC.postObj = self.postsObjects.objectAtIndex(cellIndex) as! PostsObject
                    }
                    imageEditorVC.indexLocation = col_cell_indexPath
                    imageEditorVC.notifMode = false
                    
//                    if let cell_col: PFCollectionViewCell = (cell.myCollectionView.cellForItemAtIndexPath(col_cell_indexPath) as? PFCollectionViewCell)   {
                        imageEditorVC.imageToBePresented    = cell.orignal_Image
//                    }
                    
                    self.view.addSubview(self.imageEditorVC.view)
                    self.view.bringSubviewToFront(self.imageEditorVC.view)
                
                // It refreshes cell
//                    println("kREFRESH_TAG")
//                    self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Right)
//                    cell.myCollectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: Int(0), inSection: 0), atScrollPosition: UICollectionViewScrollPosition.None, animated: false)
                case kPROFILE_TAG:
                    NOTIFY.removeObserver(self)
                    println("kPROFILE_TAG")
                    var myObject: PostsObject
                    if (self.searchActive == true)  {
                        myObject = self.searchObjects.objectAtIndex(indexPath.row) as! PostsObject
                    }
                    else    {
                        myObject = self.postsObjects.objectAtIndex(indexPath.row) as! PostsObject
                    }
                    NOTIFY.postNotificationName(NOTIF_SHOW_USER_PROFILE, object: nil, userInfo:["user" : myObject.getOwner()])
                    // CHANGED by Client -> Only Owner
//                    if (myObject.flips != nil)  {
//                        if (myObject.flips.count > 0)  {
//                            var flippedObj: FlipsObject = myObject.flips.objectAtIndex(0) as! FlipsObject
//                            NOTIFY.postNotificationName(NOTIF_SHOW_USER_PROFILE, object: nil, userInfo:["user" : flippedObj.getFlipper()])
//                        }
//                        else    {
//                            NOTIFY.postNotificationName(NOTIF_SHOW_USER_PROFILE, object: nil, userInfo:["user" : myObject.getOwner()])
//                        }
//                    }
//                    else    {
//                        NOTIFY.postNotificationName(NOTIF_SHOW_USER_PROFILE, object: nil, userInfo:["user" : myObject.getOwner()])
//                    }
                    return;
                default:
                    println("no")
                
            }
        }
        self.tableView.reloadData()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
