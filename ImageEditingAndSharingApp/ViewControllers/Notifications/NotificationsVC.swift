//
//  NotificationsVC.swift
//  FlipCast
//
//  Created by Usman Shahid on 08/06/2015.
//  Copyright (c) 2015 Granjur. All rights reserved.
//

import UIKit
import Parse
import AVFoundation
import Photos


class NotificationsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, ImageEditor_Delegare, AdobeUXImageEditorViewControllerDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate {
    
    var refreshControl:UIRefreshControl!
    
    let textCellIdentifier = "NotificationsTableCell"
    var animateView: Bool = false
    var postsObjects: NSMutableArray = NSMutableArray()
    var imageEditorVC : ImageEditor!
    var user : PFUser!
    var isViewTransformed: Bool = false
    var cellIndex : Int!
    let picker = UIImagePickerController()
    
    let SHARE_ACTION_SHEET_TAG = 10
    var sharing_postCard = UIImage()
    var isLoadingMore: Bool!
    
    var FULL_BTN: UIButton!
    
    // MARK: - OUTLETS
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingFooter: UIView!
    
    // MARK: - BUTTON ACTIONS
    
    @IBAction func categoriesClicked(sender: AnyObject) {
    }
    
    @IBAction func sideMenuClicked(sender: AnyObject) {
        // We need to move back to the normal view by clicking at Menu Button (ELSE part)
        if (!isViewTransformed) {
            FULL_BTN.hidden = false
            
            NOTIFY.removeObserver(self)
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
        
    }
    
    @IBAction func logOutClicked(sender: AnyObject) {
        
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
        }
        
        HELPER.showActivityIndicatory(self.view)
        self.postsObjects.removeAllObjects()
        loadData(kMAX_POST_LIMIT, skip: self.postsObjects.count)
    }
    
    func loadData(var limit: Int, var skip: Int) {
        self.loadingFooter.hidden = false
        if (user != nil)  {
            user = PFUser.currentUser()!
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
                        var parent_post_id: String = object[_PARENT_ID] as! String
                        flips_Edited_array.addObject(parent_post_id)
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
        
        // Find user's liked POSTS
        var query_find_user_likes = PFQuery(className:_POSTS)
        query_find_user_likes.whereKey(_LIKES, equalTo: (user.objectId!))

        // Find user's favourites POSTS
        //  CLIENT ASKED TO REMOVE FAVORITIES
//        var query_find_user_favourities = PFQuery(className:_POSTS)
//        query_find_user_favourities.whereKey(_FAVOURITIES, equalTo: user.objectId!)

        var query_find_flips_user_edited = PFQuery(className:_POSTS)
        query_find_flips_user_edited.whereKey(_OBJECT_ID, containedIn: array as [AnyObject])
        
        //  CLIENT ASKED TO REMOVE FAVORITIES
        var query = PFQuery.orQueryWithSubqueries([query_find_user, query_find_user_likes, /*query_find_user_favourities,*/ query_find_flips_user_edited])
        query.includeKey(_OWNER)
        query.orderByDescending(_UPDATED_AT)
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
        self.loadingFooter.hidden = true
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
        
        NOTIFY.addObserver(self, selector: "reloadTableView:", name:RELOAD_POSTS, object: nil)
        NOTIFY.addObserver(self, selector: "cellButtonsClicked:", name:NOTIF_CELL_IMAGE_BUTTON_CLICKED, object: nil)
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        user = PFUser.currentUser()!
        
        HELPER.showActivityIndicatory(self.view)
        loadData(kMAX_POST_LIMIT, skip: self.postsObjects.count)
        
        self.picker.delegate = self
        
        var currentUser = user
        
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
    
    // MARK: - CUSTOM IMAGE EDITOR DELEGATE
    func imageSelected(selectedImg: UIImage, hasEditedWithPost: Bool) {
        
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
        
    }
    func retakePic()    {
        //        if (isPost == true) {
        //            if (isCamera == true)   {
        //                cameraSelectClicked(UIButton())
        //            }
        //            else    {
        //                galarySelectClicked(UIButton())
        //            }
        //        }
    }
    
    // MARK: - TABLVIEW DELEGATES
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.postsObjects.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell: NotificationsTableCell = tableView.dequeueReusableCellWithIdentifier("NotificationsTableCell", forIndexPath: indexPath) as! NotificationsTableCell
        
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
        
        if ((myObject.updatedAt) != nil) {
            var currentDate: NSDate = NSDate()
            cell.timeElapsed.text = SHARED.getDateDifferenceString(currentDate, earlierDate: myObject.updatedAt!)
        }
        
        // CHANGED BY CLIENT -> Only show name of owner
        /*if (myObject.flips.count > 0)   {
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
    
    // MARK: - NOTIFICATIONS
    
    func reloadTableView(notification: NSNotification){
        
        self.tableView.reloadData()
    }
    
    func cellButtonsClicked(notification: NSNotification){
        var tag: Int = notification.userInfo!["tag"] as! Int
        
        NSLog("TAG = %d, rowIndex = %d, actualTag = %d", tag, Int(tag/10), Int(tag%10))
        cellIndex = Int(tag/10)
        var indexPath: NSIndexPath = NSIndexPath(forItem: Int(tag/10), inSection: 0)
        
        if let cell: NotificationsTableCell = (self.tableView.cellForRowAtIndexPath(indexPath) as? NotificationsTableCell)   {
            
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
                imageEditorVC.notifMode = true
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

//                imageEditorVC = storyboard!.instantiateViewControllerWithIdentifier("ImageEditor") as! ImageEditor
//                imageEditorVC.imageToBeEdited       = cell.orignal_Image
//                imageEditorVC.creationMode = true
//                self.imageEditorVC.delegate = self
//                var col_cell_indexPath: NSIndexPath = NSIndexPath(forItem: 0, inSection: 0)
//                imageEditorVC.flipsArray = nil
//                imageEditorVC.postObj = self.postsObjects.objectAtIndex(cellIndex) as! PostsObject
//                imageEditorVC.indexLocation = col_cell_indexPath
//                imageEditorVC.notifMode = false
//                
////                if let cell_col: PFCollectionViewCell = (cell.myCollectionView.cellForItemAtIndexPath(col_cell_indexPath) as? PFCollectionViewCell)   {
//                    imageEditorVC.imageToBePresented    = cell.orignal_Image
////                }
//                
//                self.view.addSubview(self.imageEditorVC.view)
//                self.view.bringSubviewToFront(self.imageEditorVC.view)
                
                //                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Right)
                //                cell.myCollectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: Int(0), inSection: 0), atScrollPosition: UICollectionViewScrollPosition.None, animated: false)
            case kPROFILE_TAG:
                println("kPROFILE_TAG")
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
