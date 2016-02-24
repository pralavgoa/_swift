//
//  ProfilePage.swift
//  FlipCast
//
//  Created by Usman Shahid on 08/06/2015.
//  Copyright (c) 2015 Granjur. All rights reserved.
//

import UIKit
import Parse
import AVFoundation
import Photos


class ProfilePage: UIViewController, UITableViewDelegate, UITableViewDataSource, ImageEditor_Delegare, AdobeUXImageEditorViewControllerDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate {
    
    var refreshControl:UIRefreshControl!
    
    let textCellIdentifier = "ProfileTableCell"
    var animateView: Bool = false
    var postsObjects: NSMutableArray = NSMutableArray()
    var imageEditorVC : ImageEditor!
    var user : PFUser!
    var timer: NSTimer!
    var isViewTransformed: Bool = false
    var cellIndex : Int!
    let picker = UIImagePickerController()
    let SHARE_ACTION_SHEET_TAG = 10
    var sharing_postCard = UIImage()
    
    var FULL_BTN: UIButton!
    var isLoadingMore: Bool!
    
    // MARK: - OUTLETS
    
    @IBOutlet weak var locationText: UILabel!
    @IBOutlet weak var timeElapsedText: UILabel!
    @IBOutlet weak var userNameText: UILabel!
    
    @IBOutlet weak var userProfilePic: UIImageView!
    @IBOutlet weak var coverPhoto: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingFooter: UIView!
    @IBOutlet weak var coverPhotoImage: UIImageView!
    
    // MARK: - BUTTON ACTIONS
    
    @IBAction func categoriesClicked(sender: AnyObject) {
    }
    
    @IBAction func sideMenuClicked(sender: AnyObject) {
        if (timer != nil)   {
            timer.invalidate()
        }
        
        // We need to move back to the normal view by clicking at Menu Button (ELSE part)
        if (!isViewTransformed) {
            FULL_BTN.hidden = false
            
            
            NOTIFY.removeObserver(self)
            if (timer != nil)   {
                timer.invalidate()
            }
            NOTIFY.postNotificationName(ADJUST_OVERLAY_ALPHA, object: nil)
            
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
            
            NOTIFY.addObserver(self, selector: "reloadTableView:", name:RELOAD_POSTS, object: nil)
            NOTIFY.addObserver(self, selector: "cellButtonsClicked:", name:NOTIF_CELL_IMAGE_BUTTON_CLICKED, object: nil)
            
            if (user.objectId != PFUser.currentUser()!.objectId)    {
                timer = NSTimer.scheduledTimerWithTimeInterval(10.0, target: self, selector:  Selector("updateUserStatus"), userInfo: nil, repeats: true)
            }
            
            NOTIFY.postNotificationName(SLIDE_VIEW_LEFT, object: nil)
            
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
    
    @IBAction func userProfilePicClicked(sender: AnyObject) {
    }
    @IBAction func coverPhotoClicked(sender: AnyObject) {
        var actionSheet = UIActionSheet(title: "Choose a Picture Method", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Gallery", "Take Photo")
        actionSheet.showInView(self.view)
    }
    
    @IBAction func logOutClicked(sender: AnyObject) {
        
    }
    
    // MARK: - CUSTOM ACTIONS
    
    func loadUserState () {
        
    }
    
    func refresh() {
        
        if (self.isLoadingMore == true) {
            return
        }
        
        if (self.isLoadingMore == false)    {
            self.isLoadingMore = true
            HELPER.showActivityIndicatory(self.view)
            self.postsObjects.removeAllObjects()
            
            loadData(kMAX_POST_LIMIT, skip: self.postsObjects.count)
        }
        
    }
    
    func loadData(var limit: Int, var skip: Int) {
        self.loadingFooter.hidden = false
        if (user != nil)  {
            if (timer != nil)   {
                timer.invalidate()
            }
            updateUserStatus()
            timer = NSTimer.scheduledTimerWithTimeInterval(10.0, target: self, selector:  Selector("updateUserStatus"), userInfo: nil, repeats: true)
        }
        else    {
            
            user = PFUser.currentUser()!
            if ((SHARED.user_loc) != nil)   {
                self.locationText.text = SHARED.user_loc
            }
            self.timeElapsedText.text = "Online"
        }

        var flips_Edited_array: NSMutableArray = NSMutableArray()
        
        var query_find_flips_user_edited = PFQuery(className:_FLIPS)
        query_find_flips_user_edited.includeKey(_OWNER)
        query_find_flips_user_edited.whereKey(_OWNER, equalTo: (user!))
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
                    self.loadPosts(flips_Edited_array, limit: limit, skip: skip)
                }
            } else {
                // Hide activity indicator
                HELPER.stopActivityIndicator(self.view)
                self.isLoadingMore = false
                
                
                let errorString = error!.userInfo?["error"] as? NSString
                // SHOW ERROR
                self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: errorString?.description, buttonTitle: "Ok"), animated: true, completion: nil)
            }
        }
    }
    
    func loadPosts(var array: NSMutableArray, var limit: Int, var skip: Int)   {
        // Find user's created POSTS
        var query_find_user = PFQuery(className:_POSTS)
        query_find_user.whereKey(_OWNER, equalTo: user!)
        
        var query_find_flips_user_edited = PFQuery(className:_POSTS)
        query_find_flips_user_edited.whereKey(_OBJECT_ID, containedIn: array as [AnyObject])
        
        
        var query = PFQuery.orQueryWithSubqueries([query_find_user, query_find_flips_user_edited])
        query.includeKey(_OWNER)
        query.orderByDescending(_CREATED_AT)
        query.limit = limit
        query.skip = skip
        
        // THIS QUERY was changed by CLIENT, its purpose was to GET all POSTS done by user and LIKED by the user
        //        var query_find_user_likes = PFQuery(className:_POSTS)
        //        query_find_user_likes.whereKey(_LIKES, equalTo: (user.objectId!))
        //
        //        var query_find_user = PFQuery(className:_POSTS)
        //        query_find_user.whereKey(_OWNER, equalTo: user!)
        //
        //        println("PFUser!.objectId! = \(user.objectId!)")
        //
        //        var query = PFQuery.orQueryWithSubqueries([query_find_user_likes, query_find_user])
        //        query.includeKey(_OWNER)
        //        query.orderByDescending(_CREATED_AT)
        
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                // The find succeeded.
                println("Successfully retrieved \(objects!.count).")
                // Do something with the found objects
                if let objects = objects as? [PFObject] {
                    for object in objects {
                        println("PostsID = \(object.objectId)")
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
                // Hide activity indicator
                self.refreshControl.endRefreshing()
                HELPER.stopActivityIndicator(self.view)
                
                let errorString = error!.userInfo?["error"] as? NSString
                // SHOW ERROR
                self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: errorString?.description, buttonTitle: "Ok"), animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - IMAGE PICKER DELEGATE
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject])    {
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            
            if (picker.sourceType == UIImagePickerControllerSourceType.Camera) {
                self.picker.cameraViewTransform = CGAffineTransformMakeTranslation(0, 0.0);
            }
            
            var image: UIImage
            if let img: UIImage = (info[UIImagePickerControllerEditedImage]) as? UIImage {
                image = info[UIImagePickerControllerEditedImage] as! UIImage
                NSLog("Edited")
            }
            else    {
                image = info[UIImagePickerControllerOriginalImage] as! UIImage
                NSLog("NOt Edited")
            }
            
            //Create camera overlay
            let pickerFrame = CGRectMake(0, UIApplication.sharedApplication().statusBarFrame.size.height, self.picker.view.bounds.width, self.picker.view.bounds.height - self.picker.navigationBar.bounds.size.height - self.picker.toolbar.bounds.size.height)
            let squareFrame = CGRectMake(0.0, pickerFrame.height/2 - self.coverPhotoImage.frame.size.height/2, self.coverPhotoImage.frame.size.width, self.coverPhotoImage.frame.size.height)
            
            var coverImg = Toucan(image: image).resize(CGSize(width: self.coverPhotoImage.frame.size.width, height: self.coverPhotoImage.frame.size.height), fitMode: Toucan.Resize.FitMode.Crop).image//HELPER.croppIngimage(image, toRect: self.coverPhotoImage.frame)
            var imageData = UIImageJPEGRepresentation(coverImg, 1.0)
            
            let imageFile = PFFile(data: imageData)
            self.user!.setObject(imageFile, forKey: _COVER)
            HELPER.showActivityIndicatory(self.view)
            
            
            
            self.coverPhotoImage!.contentMode = UIViewContentMode.ScaleAspectFill
            
            PFUser.currentUser()!.saveInBackgroundWithBlock {
                (success: Bool, error: NSError?) -> Void in
                if (success) {
                    self.coverPhotoImage.image = coverImg
//                    self.coverPhotoImage.image = coverImg
//                    self.coverPhotoImage.image = coverImg
                    HELPER.stopActivityIndicator(self.view)
                    
                } else {
                    HELPER.stopActivityIndicator(self.view)
                    
                    let errorString = error!.userInfo?["error"] as? NSString
                    // SHOW ERROR
                    self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: errorString?.description, buttonTitle: "Ok"), animated: true, completion: nil)
                }
            }
            
        })
        
//        SHARED.offsetValue = 0.0
        
        
    }
    func imagePickerControllerDidCancel(picker: UIImagePickerController)   {
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
        dismissViewControllerAnimated(false, completion: nil)
        
        NSLog("SHARED.offsetValue = %f", SHARED.offsetValue)
        if (picker.sourceType == UIImagePickerControllerSourceType.Camera) {
            self.picker.cameraViewTransform = CGAffineTransformMakeTranslation(0, 0.0);
        }
//        SHARED.offsetValue = 0.0
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
                SHARED.offsetValue = 0.0
                PHPhotoLibrary.requestAuthorization
                    { (PHAuthorizationStatus status) -> Void in
                        switch (status)
                        {
                        case .Authorized:
                            // Permission Granted
//                            self.picker.allowsEditing = true
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
                            self.picker.allowsEditing = true
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
                
                if AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) ==  AVAuthorizationStatus.Authorized   {
                    // Already Authorized
//                    self.picker.allowsEditing = true
                    self.picker.sourceType = .Camera
                    
                    //Create camera overlay
                    let pickerFrame = CGRectMake(0, UIApplication.sharedApplication().statusBarFrame.size.height, self.picker.view.bounds.width, self.picker.view.bounds.height - self.picker.navigationBar.bounds.size.height - self.picker.toolbar.bounds.size.height)
                    let squareFrame = CGRectMake(0.0, pickerFrame.height/2 - self.coverPhotoImage.frame.size.height/2, self.coverPhotoImage.frame.size.width, self.coverPhotoImage.frame.size.height)
                    UIGraphicsBeginImageContext(pickerFrame.size)
                    
                    let context = UIGraphicsGetCurrentContext()
                    CGContextSaveGState(context)
                    CGContextAddRect(context, CGContextGetClipBoundingBox(context))
                    CGContextMoveToPoint(context, squareFrame.origin.x, squareFrame.origin.y)
                    CGContextAddLineToPoint(context, squareFrame.origin.x + squareFrame.width, squareFrame.origin.y)
                    CGContextAddLineToPoint(context, squareFrame.origin.x + squareFrame.width, squareFrame.origin.y + squareFrame.size.height)
                    CGContextAddLineToPoint(context, squareFrame.origin.x, squareFrame.origin.y + squareFrame.size.height)
                    CGContextAddLineToPoint(context, squareFrame.origin.x, squareFrame.origin.y)
                    CGContextEOClip(context)
                    CGContextMoveToPoint(context, pickerFrame.origin.x, pickerFrame.origin.y)
                    CGContextSetRGBFillColor(context, 0, 0, 0, 1)
                    CGContextFillRect(context, pickerFrame)
                    CGContextRestoreGState(context)
                    
                    let overlayImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext();
                    
                    let overlayView = UIImageView(frame: pickerFrame)
                    overlayView.image = overlayImage
                    self.picker.cameraOverlayView = overlayView
                    
                    SHARED.offsetValue = 25.0
                    
                    if (DeviceType.IS_IPHONE_5 == true) {
                        SHARED.offsetValue = 32.0
                    }
                    else if (DeviceType.IS_IPHONE_6)    {
                        SHARED.offsetValue = 46.0
                    }
                    else if (DeviceType.IS_IPHONE_6P)    {
                        SHARED.offsetValue = 60.0
                    }
                    
                    self.picker.cameraViewTransform = CGAffineTransformMakeTranslation(0, SHARED.offsetValue);
                    
                    self.presentViewController(picker, animated: true, completion: nil)
                    
                }
                else    {
                    AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
                        if granted == true
                        {
                            // User granted
                            self.picker.allowsEditing = true
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
    
    // MARK: - PHOTO EDITOR DELEGATE
    func photoEditor(photoEditor: AdobeUXImageEditorViewController, finishedWithImage image: UIImage) {
        
        let imageData = UIImageJPEGRepresentation(image, 1)
        HELPER.showActivityIndicatory(self.view)
        let imageFile:PFFile = PFFile(data: imageData)
        
        var myObject: PostsObject = self.postsObjects.objectAtIndex(cellIndex) as! PostsObject
        
        var flipObject          = PFObject(className:_FLIPS)
//        flipObject[_IS_PRIVATE] = false
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
        photoEditor .dismissViewControllerAnimated(true, completion: nil)
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
    
    // MARK: - DEFAULTS
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isLoadingMore = false
        self.coverPhotoImage.contentMode = .ScaleAspectFill
        
        self.coverPhotoImage.image = UIImage(named: "cover.png")
        self.coverPhotoImage.image = UIImage(named: "cover.png")
        self.coverPhotoImage.image = UIImage(named: "cover.png")
        
        
        
        self.loadingFooter.hidden = true
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
        
        NOTIFY.addObserver(self, selector: "reloadTableView:", name:RELOAD_POSTS, object: nil)
        NOTIFY.addObserver(self, selector: "cellButtonsClicked:", name:NOTIF_CELL_IMAGE_BUTTON_CLICKED, object: nil)
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.timeElapsedText.text = " "
        self.locationText.text = " "
        
        HELPER.showActivityIndicatory(self.view)
        loadData(kMAX_POST_LIMIT, skip: self.postsObjects.count)
        
        self.picker.delegate = self
        
        
//        HELPER.showActivityIndicatory(self.view)
        
        var currentUser = user
        if (user.objectId != PFUser.currentUser()!.objectId)    {
            self.coverPhoto.enabled = false
        }
        
        // PROFILE PIC
        if let userImageFile = currentUser?.objectForKey(_PICTURE) as? PFFile {
            userImageFile.getDataInBackgroundWithBlock({ (imageData: NSData?, error: NSError?) -> Void in
                if error == nil {
                    if imageData != nil{
                        let image = UIImage(data:imageData!)
                        self.userProfilePic.image = image
                        self.userProfilePic.layer.cornerRadius = self.userProfilePic.frame.size.width/2.0
                        self.userProfilePic.contentMode = UIViewContentMode.ScaleAspectFill
                        self.userProfilePic.clipsToBounds = true
                        self.userProfilePic.layer.borderWidth = 2.0
                        var myColor : UIColor = UIColor(red: 112/255, green: 102/255, blue: 110/255, alpha: 1)
                        self.userProfilePic.layer.borderColor = myColor.CGColor
                    }
                    
                    // Hide activity indicator
//                    HELPER.stopActivityIndicator(self.view)
                    
                }
                else if let error = error {
                    // Hide activity indicator
//                    HELPER.stopActivityIndicator(self.view)
                    
                    let errorString = error.userInfo?["error"] as? NSString
                    // SHOW ERROR
                    self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: errorString?.description, buttonTitle: "Ok"), animated: true, completion: nil)
                }
            })
        }
        // COVER
        if let userImageFile = currentUser?.objectForKey(_COVER) as? PFFile {
            userImageFile.getDataInBackgroundWithBlock({ (imageData: NSData?, error: NSError?) -> Void in
                if error == nil {
                    if imageData != nil{
                        let image = UIImage(data:imageData!)
                        self.coverPhotoImage.image = image
                        self.coverPhotoImage.image = image
                        self.coverPhotoImage.image = image
                    }
                    
                    // Hide activity indicator
                    //                    HELPER.stopActivityIndicator(self.view)
                    
                }
                else if let error = error {
                    // Hide activity indicator
                    //                    HELPER.stopActivityIndicator(self.view)
                    
                    let errorString = error.userInfo?["error"] as? NSString
                    // SHOW ERROR
                    self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: errorString?.description, buttonTitle: "Ok"), animated: true, completion: nil)
                }
            })
        }
        userNameText.text = user[_FULLNAME] as! String!
        
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
        if (timer != nil)   {
            timer.invalidate()
        }
    }
    
    func degree2radian(a:CGFloat)->CGFloat {
        let b = CGFloat(M_PI) * a/180
        return b
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - CUSTOM IMAGE EDITOR DELEGATE
    func imageSelected(selectedImg: UIImage, hasEditedWithPost: Bool)   {
        
        let imageData = UIImageJPEGRepresentation(selectedImg, 1)
        HELPER.showActivityIndicatory(self.view)
        let imageFile:PFFile = PFFile(data: imageData)
        
        var myObject: PostsObject = self.postsObjects.objectAtIndex(cellIndex) as! PostsObject
        
        var flipObject          = PFObject(className:_FLIPS)
//        flipObject[_IS_PRIVATE] = false
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
    func retakePic()    {

    }
    
    // MARK: - TABLVIEW DELEGATES
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.postsObjects.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell: ProfileTableCell = tableView.dequeueReusableCellWithIdentifier("ProfileTableCell", forIndexPath: indexPath) as! ProfileTableCell
        
        // Default images
        cell.profilePicView.image = UIImage(named: "user_upload_img.png")
        //        cell.flippedImgView1.image = UIImage(named: "user_upload_img.png")
        
        
        
        // Load profile pic
        var myObject: PostsObject = self.postsObjects.objectAtIndex(indexPath.row) as! PostsObject
        
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
                cell.profilePicView.file = flippedObj.flipper.image
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
            cell.profilePicView.loadInBackground({ (image : UIImage?, error: NSError?) -> Void in
                if (error == nil)   {
                    cell.profilePicView.image = image
                    cell.profilePicView.viewWithTag(100)?.removeFromSuperview()
                }
            })
//        }
        
        // Load Flipped pic
        //        cell.flippedImgView1.file = myObject.image
        //        cell.flippedImgView1.loadInBackground()
        
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
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        NSLog("DIFFENDCE = %f", (maximumOffset - currentOffset))
        if ( (maximumOffset - currentOffset) <= 0 && (maximumOffset - currentOffset) >= -5) {
            NSLog("LoadMore")
            if (self.isLoadingMore == false)    {
                self.isLoadingMore = true
                loadData(kMAX_POST_LIMIT, skip: self.postsObjects.count)
            }
            
            
            //                loadSegment(items.count, size: PageSize)
        }
    }
    
    // MARK: - SCHEDULAR
    
    func updateUserStatus() {
        // Something after a delay
        if (SHARED.isAppActive == true) {
            var query = PFUser.query()
            query!.whereKey(_OBJECT_ID, equalTo: user.objectId!)
            query!.findObjectsInBackgroundWithBlock {
                (objects: [AnyObject]?, error: NSError?) -> Void in
                
                if error == nil {
                    // The find succeeded.
//                    println("Successfully retrieved \(objects!.count).")
                    // Do something with the found objects
                    if let objects = objects as? [PFObject] {
                        for object in objects {
//                            println("ID = \(object.objectId)")
                            
//                            let geoPoint: PFGeoPoint = object[USER_LOCATION]
                            
                            if let geoPoint : PFGeoPoint = object.valueForKey(USER_LOCATION) as? PFGeoPoint {
//                            if (geoPoint != nil)    {
                                let currentLocation = CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                                CLGeocoder().reverseGeocodeLocation (currentLocation, completionHandler: {
                                    placemarks, error in
                                    
                                    if error == nil && placemarks.count > 0 {
                                        var placeMark = placemarks.last as? CLPlacemark
                                        println("\(placeMark!.locality), \(placeMark!.country)")
                                        self.locationText.text = "\(placeMark!.locality), \(placeMark!.country)"
                                    }
                                })
                            }
                            
                            var currentDate: NSDate = NSDate()
                            let timeDuration = SHARED.getDateDifference(currentDate, earlierDate: object.updatedAt!)
                            if (timeDuration.sec < 31)  {
                                self.timeElapsedText.text = "Online"
                            }
                            else {
                                self.timeElapsedText.text = String(format: "%@ ago", SHARED.getDateDifferenceString(currentDate, earlierDate: object.updatedAt!))
                            }
                        }
                    }
                } else {
                    
                    let errorString = error!.userInfo?["error"] as? NSString
                    // SHOW ERROR
                }
            }
        }
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
        
        if let cell: ProfileTableCell = (self.tableView.cellForRowAtIndexPath(indexPath) as? ProfileTableCell)   {
            
            switch  (Int(tag%10)) {
            case kIMG_FLIP1_TAG:
                imageEditorVC = storyboard!.instantiateViewControllerWithIdentifier("ImageEditor") as! ImageEditor
                imageEditorVC.imageToBeEdited       = cell.orignal_Image
                self.imageEditorVC.delegate = self
                var col_cell_indexPath: NSIndexPath = notification.userInfo!["indexPath"] as! NSIndexPath
                var flipsArray = notification.userInfo!["flipsArray"] as! NSMutableArray
                imageEditorVC.flipsArray = flipsArray
                imageEditorVC.postObj = self.postsObjects.objectAtIndex(cellIndex) as! PostsObject
                imageEditorVC.indexLocation = col_cell_indexPath
                imageEditorVC.notifMode = false
                imageEditorVC.creationMode = false
                
                if let cell_col: PFCollectionViewCell = (cell.myCollectionView.cellForItemAtIndexPath(col_cell_indexPath) as? PFCollectionViewCell)   {
                    imageEditorVC.imageToBePresented    = cell_col.imageView.image
                }
                
//                UIView.transitionWithView(self.view, duration: 1.0, options: UIViewAnimationOptions.TransitionFlipFromLeft, animations: {
                    self.view.addSubview(self.imageEditorVC.view)
                    self.view.bringSubviewToFront(self.imageEditorVC.view)
                    
//                    }, completion: { (fininshed: Bool) -> () in
//                })
                
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
                var myObject: PostsObject = self.postsObjects.objectAtIndex(indexPath.row) as! PostsObject
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
                var myObject: PostsObject = self.postsObjects.objectAtIndex(indexPath.row) as! PostsObject
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
//                                        println("ID = \(flipObject.objectId)")
                                        
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
                println("kREFRESH_TAG")
//                if let cell_col: PFCollectionViewCell = (cell.myCollectionView.cellForItemAtIndexPath(NSIndexPath(forItem: Int(0), inSection: 0)) as? PFCollectionViewCell)   {
//                    var editor = AdobeUXImageEditorViewController(image: cell_col.imageView.image)
//                    editor.delegate = self
//                    self.presentViewController(editor, animated: true, completion: nil)
//                }

                imageEditorVC = storyboard!.instantiateViewControllerWithIdentifier("ImageEditor") as! ImageEditor
                imageEditorVC.imageToBeEdited       = cell.orignal_Image
                imageEditorVC.creationMode = true
                self.imageEditorVC.delegate = self
                var col_cell_indexPath: NSIndexPath = NSIndexPath(forItem: 0, inSection: 0)
                imageEditorVC.flipsArray = nil
                imageEditorVC.postObj = self.postsObjects.objectAtIndex(cellIndex) as! PostsObject
                imageEditorVC.indexLocation = col_cell_indexPath
                imageEditorVC.notifMode = false
                
//                if let cell_col: PFCollectionViewCell = (cell.myCollectionView.cellForItemAtIndexPath(col_cell_indexPath) as? PFCollectionViewCell)   {
                    imageEditorVC.imageToBePresented    = cell.orignal_Image//cell_col.imageView.image
//                }
                
                self.view.addSubview(self.imageEditorVC.view)
                self.view.bringSubviewToFront(self.imageEditorVC.view)
                
//                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Right)
//                cell.myCollectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: Int(0), inSection: 0), atScrollPosition: UICollectionViewScrollPosition.None, animated: false)
            case kPROFILE_TAG:
                NOTIFY.removeObserver(self)
                if (timer != nil)   {
                    timer.invalidate()
                }
                println("kPROFILE_TAG")
                var myObject: PostsObject = self.postsObjects.objectAtIndex(indexPath.row) as! PostsObject
                
                NOTIFY.postNotificationName(NOTIF_SHOW_USER_PROFILE, object: nil, userInfo:["user" : myObject.getOwner()])
                // CHANGED by Client -> Only Owner
//                if (myObject.flips != nil)  {
//                    if (myObject.flips.count > 0)  {
//                        var flippedObj: FlipsObject = myObject.flips.objectAtIndex(0) as! FlipsObject
//                        NOTIFY.postNotificationName(NOTIF_SHOW_USER_PROFILE, object: nil, userInfo:["user" : flippedObj.getFlipper()])
//                    }
//                    else    {
//                        NOTIFY.postNotificationName(NOTIF_SHOW_USER_PROFILE, object: nil, userInfo:["user" : myObject.getOwner()])
//                    }
//                }
//                else    {
//                    NOTIFY.postNotificationName(NOTIF_SHOW_USER_PROFILE, object: nil, userInfo:["user" : myObject.getOwner()])
//                }
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
