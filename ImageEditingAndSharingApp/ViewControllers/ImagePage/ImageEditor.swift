//
//  ImageEditor.swift
//  FlipCast
//
//  Created by Usman Shahid on 17/06/2015.
//  Copyright (c) 2015 Granjur. All rights reserved.
//

import UIKit
import Parse
import AVFoundation
import Photos

protocol ImageEditor_Delegare : NSObjectProtocol  {
    func imageSelected(selectedImg: UIImage, hasEditedWithPost: Bool)
    func retakePic()
}

class ImageEditor: UIViewController, AdobeUXImageEditorViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIActionSheetDelegate {
    
    var editedPost: Bool!
    var delegate : ImageEditor_Delegare?
    var imageToBeEdited     : UIImage!
    var imageToBePresented  : UIImage!
    var flipsArray  : NSMutableArray!
    var orignal_Image : UIImage!
    var indexLocation : NSIndexPath!
    var postObj : PostsObject!
    var creationMode : Bool!
    var editMode : Bool!
    var notifMode : Bool!   // If it is Notifications mode then we must show all flips according to creation date, main pic will go at the last

    // MARK: - OUTLETS
    @IBOutlet weak var fullScreenImage: UIImageView!
    
    @IBOutlet weak var pageController: UIPageControl!
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var helpBtn: UIButton!
    @IBOutlet weak var bottomBar: UIImageView!
    @IBOutlet weak var profilePic: PFImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var titleText: UILabel!
    
    @IBOutlet weak var myCollectionView: UICollectionView!
    
    @IBOutlet weak var helpView: UIView!
    // MARK: - BUTTON ACTIONS
    
    @IBAction func helpButtonClicked(sender: AnyObject) {
        self.helpView.hidden = false
    }
    @IBAction func hideHelp(sender: AnyObject) {
        helpView.hidden = true
    }
    @IBAction func startOverClicked(sender: AnyObject) {
//        UIView.transitionWithView(self.view, duration: 1.0, options: UIViewAnimationOptions.TransitionFlipFromLeft, animations: {
//            
//            }, completion: { (fininshed: Bool) -> () in
                self.view.removeFromSuperview()
//        })
    }
    
    @IBAction func designClicked(sender: AnyObject) {
        
//        NSLog("---- %@",self.myCollectionView.indexPathsForVisibleItems())
  
        //        // Changed by CLient, only change SWIPED IMAGE -> previously it is only original image
        //        if let cell_col: CollectionViewCell = (self.myCollectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) as? CollectionViewCell)   {

        NSLog("indexLocation = %d", indexLocation.row)
        
        if let cell_col: CollectionViewCell = (self.myCollectionView.cellForItemAtIndexPath(indexLocation) as? CollectionViewCell)   {
                    imageToBeEdited = cell_col.imageView.image
            NSLog("indexLocation = %d", indexLocation.row)
            
        }
        var editor = AdobeUXImageEditorViewController(image: imageToBeEdited)
        editor.delegate = self
        
        self.myCollectionView.reloadData()
        self.presentViewController(editor, animated: true, completion: nil)
    }
    
    @IBAction func shareClicked(sender: AnyObject) {
//        APP_DELEGATE.shareFBPhoto(self.fullScreenImage.image!) //shareFBLink(NSURL(string: postObj.image.url!)!)
        var actionSheet = UIActionSheet(title: "Choose a Sharing Method", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Facebook", "Email", "SMS")
        actionSheet.showInView(self.view)
    }
   
    @IBAction func saveClicked(sender: AnyObject) {
        APP_DELEGATE.saveToSpecialGalary(self.imageToBeEdited)
    }
    
    @IBAction func deleteClicked(sender: AnyObject) {
        if let delegate = self.delegate {
            delegate.retakePic()
        }
//        UIView.transitionWithView(self.view, duration: 1.0, options: UIViewAnimationOptions.TransitionFlipFromLeft, animations: {
//            
//            }, completion: { (fininshed: Bool) -> () in
                self.view.removeFromSuperview()
//        })
    }
    @IBAction func doneClicked(sender: AnyObject) {
        if let delegate = self.delegate {
            
            // Changed by CLient, only change SWIPED IMAGE -> previously it is only original image
//            if let cell_col: CollectionViewCell = (self.myCollectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) as? CollectionViewCell)   
            if let cell_col: CollectionViewCell = (self.myCollectionView.cellForItemAtIndexPath(indexLocation) as? CollectionViewCell)  {
                self.fullScreenImage.image = cell_col.imageView.image
            }
            
            if (creationMode == false)  {
                creationMode = true
                if (creationMode == true) {
                    for index in 1...5  {
                        self.view.viewWithTag(index)?.hidden = false
                    }
                    self.myCollectionView.scrollEnabled = false
                    self.bottomBar.hidden = false
                    self.helpBtn.hidden = true
                    self.postButton.hidden = false
                    self.myCollectionView.hidden = true
                    self.profilePic.hidden = true
                    self.userName.hidden = true
                    self.fullScreenImage.hidden = false
                    self.pageController.hidden = true
                    return
                }
            }
            
            delegate.imageSelected(self.fullScreenImage.image!, hasEditedWithPost: self.editedPost)
        }
//        self.transitionFromViewController(self, toViewController: self.parentViewController!, duration: 1.0, options: UIViewAnimationOptions.TransitionFlipFromBottom, animations: nil) { (Bool) -> Void in
        UIView.transitionWithView(self.view, duration: 1.0, options: UIViewAnimationOptions.TransitionFlipFromLeft, animations: {
            
            }, completion: { (fininshed: Bool) -> () in
                self.view.removeFromSuperview()
        })
//        }
    }
    
    @IBAction func backClicked(sender: AnyObject) {
        if (creationMode == true)   {
//            UIView.transitionWithView(self.view, duration: 1.0, options: UIViewAnimationOptions.TransitionFlipFromLeft, animations: {
//                
//                }, completion: { (fininshed: Bool) -> () in
                    self.view.removeFromSuperview()
//            })
            
        }
        else if (editMode == true)   {
            designClicked(UIButton())
        }
        else    {
//            UIView.transitionWithView(self.view, duration: 1.0, options: UIViewAnimationOptions.TransitionFlipFromLeft, animations: {
//                
//                }, completion: { (fininshed: Bool) -> () in
                    self.view.removeFromSuperview()
//            })
        }
    }
    
    // MARK: - DEFAULTS
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleText.hidden = true
        editedPost = false
        self.fullScreenImage.contentMode = UIViewContentMode.ScaleAspectFit
        self.fullScreenImage.clipsToBounds = true
        editMode = false
        
        //self.postButton.hidden = true
            // Client asked to show Flip btn
            self.postButton.hidden = false
        self.profilePic.layer.cornerRadius = self.profilePic.frame.size.width/2.0
        self.profilePic.layer.borderWidth = 2.0
        self.profilePic.contentMode = UIViewContentMode.ScaleAspectFill
        self.profilePic.clipsToBounds = true
        var myColor : UIColor = UIColor(red: 112/255, green: 102/255, blue: 110/255, alpha: 1)
        self.profilePic.layer.borderColor = myColor.CGColor
        
        var upSwipe = UISwipeGestureRecognizer(target: self, action: Selector("handleSwipes:"))
        upSwipe.direction = .Up
        view.addGestureRecognizer(upSwipe)
        
        self.fullScreenImage.image = imageToBePresented
        
        self.view.transform = CGAffineTransformMakeScale(0.1, 0.1)
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.view.transform = CGAffineTransformMakeScale(1.0, 1.0)
            }, completion: { finished in
                println("View Moved :)")
        })
        
//        if (USER_DEF.boolForKey(HIDE_TUTORIAL))  {
            self.helpView.hidden = true
//        }
        
        if (postObj == nil) {
            self.profilePic.hidden = true
            self.userName.hidden = true
        }
        
        USER_DEF.setBool(true, forKey: HIDE_TUTORIAL)
        USER_DEF.synchronize()
        
        self.myCollectionView.delegate = self
        self.myCollectionView.dataSource = self
//        self.myCollectionView!.registerClass(CollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        
        self.myCollectionView.scrollToItemAtIndexPath(self.indexLocation, atScrollPosition: UICollectionViewScrollPosition.Right, animated: true)
        
        
        if (creationMode == true) {
            for index in 1...5  {
                self.view.viewWithTag(index)?.hidden = false
            }
            self.myCollectionView.scrollEnabled = false
            self.bottomBar.hidden = false
            self.helpBtn.hidden = true
            self.postButton.hidden = false
            self.myCollectionView.hidden = true
            self.profilePic.hidden = true
            self.userName.hidden = true
            self.fullScreenImage.hidden = false
            self.pageController.hidden = true
        }
        else    {
            for index in 1...5  {
                self.view.viewWithTag(index)?.hidden = true
            }
            self.pageController.hidden = false
            self.myCollectionView.scrollEnabled = true
            self.bottomBar.hidden = true
            //self.helpBtn.hidden = false
            // Client asked not to show help btn
            self.helpBtn.hidden = true
            //self.postButton.hidden = true
            // Client asked to show Flip btn
            self.postButton.hidden = false
            self.myCollectionView.hidden = false
            self.profilePic.hidden = false
            self.userName.hidden = false
            self.fullScreenImage.hidden = true
        }
        
        if (notifMode == true)  {
            self.helpBtn.hidden = true
            self.postButton.hidden = true
            self.pageController.hidden = false
        }
        
        self.pageController.currentPage = indexLocation.row
        
        self.pageController.pageIndicatorTintColor = UIColor.grayColor()
        self.pageController.currentPageIndicatorTintColor = UIColor(red: 88/255, green: 32/255, blue: 44/255, alpha: 1)
        
//        self.myCollectionView.reloadData()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: PHOTO EDITOR DELEGATE
    func photoEditor(photoEditor: AdobeUXImageEditorViewController, finishedWithImage image: UIImage) {
        
        editedPost = true
        self.fullScreenImage.image = image
        self.imageToBeEdited = image
        
        if (creationMode == true) {
            for index in 1...5  {
                self.view.viewWithTag(index)?.hidden = false
            }
            self.myCollectionView.scrollEnabled = false
            self.bottomBar.hidden = false
            self.helpBtn.hidden = true
            self.postButton.hidden = false
            self.myCollectionView.hidden = true
            self.profilePic.hidden = true
            self.userName.hidden = true
            self.fullScreenImage.hidden = false
            self.pageController.hidden = true
        }
        else if (editMode == true) {
            for index in 1...5  {
                self.view.viewWithTag(index)?.hidden = false
            }
            self.myCollectionView.scrollEnabled = false
            self.bottomBar.hidden = false
            self.helpBtn.hidden = true
            self.postButton.hidden = false
            self.fullScreenImage.hidden = true
            self.pageController.hidden = true
        }
        if let cell_col: CollectionViewCell = (self.myCollectionView.cellForItemAtIndexPath(indexLocation) as? CollectionViewCell)  {
        
//        if let cell_col: CollectionViewCell = (self.myCollectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) as? CollectionViewCell)   {
            cell_col.imageView.image = imageToBeEdited
        }
        
        photoEditor.dismissViewControllerAnimated(true, completion: nil)
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
        editedPost = false
        photoEditor .dismissViewControllerAnimated(true, completion: nil)
        editMode = false
        
        if (creationMode == true) {
            for index in 1...5  {
                self.view.viewWithTag(index)?.hidden = false
            }
            self.myCollectionView.scrollEnabled = false
            self.bottomBar.hidden = false
            self.helpBtn.hidden = true
            self.postButton.hidden = false
            self.myCollectionView.hidden = true
            self.profilePic.hidden = true
            self.userName.hidden = true
            self.fullScreenImage.hidden = false
            self.pageController.hidden = true
        }
        else    {
            for index in 1...5  {
                self.view.viewWithTag(index)?.hidden = true
            }
            //self.postButton.hidden = true
            // Client asked to show Flip btn
            self.postButton.hidden = false
            //self.helpBtn.hidden = false
            // Client asked not to show help btn
            self.helpBtn.hidden = true
            self.myCollectionView.scrollEnabled = true
            bottomBar.hidden = true
            self.fullScreenImage.hidden = true
            self.pageController.hidden = false
        }
    }
    
    // MARK: - ACTION SHEET DELEGATE
    // Called when a button is clicked. The view will be automatically dismissed after this call returns
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        
    }
    
    // Avoid presenting controller when action sheet is already dismissing
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int)   { // after animation
        // FACEBOOK
        if (buttonIndex == 1) {
            APP_DELEGATE.shareFBPhoto(self.fullScreenImage.image!)
        }
        // EMAIL
        if (buttonIndex == 2) {
            APP_DELEGATE.sendEmail_Image(SHARE_TEXT, image: self.fullScreenImage.image!)
        }
        // SMS
        if (buttonIndex == 3) {
            APP_DELEGATE.sendMessage_Image(SHARE_TEXT, image: self.fullScreenImage.image!)
        }
    }
    // Called when we cancel a view (eg. the user clicks the Home button). This is not called when the user clicks the cancel button.
    // If not defined in the delegate, we simulate a click in the cancel button
    func actionSheetCancel(actionSheet: UIActionSheet)  {
        
    }
    
    // MARK: - SWIPE GESTURES
    
    func handleSwipes(sender:UISwipeGestureRecognizer) {
        self.myCollectionView.reloadData()
        
        if (notifMode == false)    {
            if (sender.direction == .Up) {
                
                if let cell_col: CollectionViewCell = (self.myCollectionView.cellForItemAtIndexPath(indexLocation) as? CollectionViewCell)  {
                    self.fullScreenImage.image = cell_col.imageView.image
                    NSLog("indexLocation = %f", indexLocation.row)
                }
                editMode = true
                self.creationMode = true
                if (creationMode == true) {
                    for index in 1...5  {
                        self.view.viewWithTag(index)?.hidden = false
                    }
                    self.myCollectionView.scrollEnabled = false
                    self.bottomBar.hidden = false
                    self.helpBtn.hidden = true
                    self.postButton.hidden = false
                    self.myCollectionView.hidden = true
                    self.profilePic.hidden = true
                    self.userName.hidden = true
                    self.fullScreenImage.hidden = false
                    self.pageController.hidden = true
                }
                // flow changed by client on 3rd August
                // designClicked(UIButton())
            }
        }
    }
    
    // MARK: - COLLECTION VIEW
    
    // MARK: - CollectionView data source
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int   {
        if (self.flipsArray != nil) {
            //            NSLog("self.flipsArray.count = %d", self.flipsArray.count)
            self.pageController.numberOfPages = self.flipsArray.count+1
            if (self.flipsArray.count+1 >= 20)  {
                self.pageController.numberOfPages = 20
            }
            if (self.flipsArray.count == 0) {
                self.pageController.numberOfPages = 0
                self.pageController.hidden = true
            }
            
            return self.flipsArray.count+1  // 1 is original image and other are flips
        }
        else    {
            self.pageController.hidden = true
            return 1
        }
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell    {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as! CollectionViewCell
        
        if (indexPath.row >= 20)  {
            self.pageController.currentPage = 20
        }
        else    {
            self.pageController.currentPage = indexPath.row
        }
        
        //        if (indexPath.row > 0)  {
        // Load profile pic

//        cell.imageView.image = UIImage(named: "user_upload_img.png")        
//        cell.contentMode = UIViewContentMode.ScaleAspectFill
        
//        if (cell.imageView != nil)  {
        
//        cell.imageView.clipsToBounds = true
//        cell.imageView.contentMode = UIViewContentMode.ScaleAspectFill
//        cell.imageView.image = UIImage(named: "user_upload_img.png")
        
//        cell.imageView.frame = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height)
        cell.imageView.contentMode = UIViewContentMode.ScaleAspectFit
        cell.imageView.clipsToBounds = true
        
        cell.imageView.image = UIImage(named: "loader.png")
        
//        NSLog("FRAME = [%f, %f] -> (%f, %f) ", cell.imageView.frame.origin.x, cell.imageView.frame.origin.y, cell. imageView.frame.size.width, cell.imageView.frame.size.height)
        
        // LOAD ORIGNAL IMAGE ONLY
        if (notifMode == true)  {
            
            /*if (self.flipsArray != nil)  {
                if (self.flipsArray.count > 0)  {
                    if (indexPath.row == self.flipsArray.count) {
                        cell.imageView.file = postObj.image
                        cell.imageView.loadInBackground()
                        orignal_Image = cell.imageView.image
                        self.userName.text = postObj.owner.fullName
                        self.profilePic.file = postObj.owner.image
                        self.profilePic.loadInBackground()
                    }
                    else    {
                        var myObject: FlipsObject = self.flipsArray.objectAtIndex(indexPath.row) as! FlipsObject
                        cell.imageView.file = myObject.image
                        cell.imageView.loadInBackground()
                        self.profilePic.file = postObj.owner.image
                        self.userName.text = postObj.owner.fullName
                        self.profilePic.loadInBackground()
                    }
                }
            }
            else if (postObj != nil) {
                cell.imageView.file = postObj.image
                cell.imageView.loadInBackground()
                orignal_Image = cell.imageView.image
                self.userName.text = postObj.owner.fullName
                self.profilePic.file = postObj.owner.image
                self.profilePic.loadInBackground()
            }
            */
            // CHANGED BY CLIENT -> Only show name of owner ^^^
            
            if (self.flipsArray != nil)  {
                if (self.flipsArray.count > 0)  {
                    if (indexPath.row == self.flipsArray.count) {
                        cell.imageView.file = postObj.image
                        cell.imageView.loadInBackground()
                        orignal_Image = cell.imageView.image
                        self.userName.text = postObj.owner.fullName
                        self.profilePic.file = postObj.owner.image
                        self.profilePic.loadInBackground()
                    }
                    else    {
                        var myObject: FlipsObject = self.flipsArray.objectAtIndex(indexPath.row) as! FlipsObject
                        cell.imageView.file = myObject.image
                        cell.imageView.loadInBackground()
                        self.profilePic.file = myObject.flipper.image
                        self.userName.text = myObject.flipper.fullName
                        self.profilePic.loadInBackground()
                    }
                }
            }
            else if (postObj != nil) {
                cell.imageView.file = postObj.image
                cell.imageView.loadInBackground()
                orignal_Image = cell.imageView.image
                self.userName.text = postObj.owner.fullName
                self.profilePic.file = postObj.owner.image
                self.profilePic.loadInBackground()
            }
            
        }
        else    {
            // OTHER MODE
            
            if (indexPath.row == 0) {
                //                    var myObject: FlipsObject = self.flipsArray.objectAtIndex(0) as! FlipsObject
                if (postObj != nil)  {
                    cell.imageView.file = postObj.image
                    cell.imageView.loadInBackground({ (image :UIImage?, error :NSError?) -> Void in
                        cell.imageView.frame = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height)
                        cell.imageView.contentMode = UIViewContentMode.ScaleAspectFit
                        cell.imageView.clipsToBounds = true
                        cell.imageView.image = image
                    }) //loadInBackground()
                    orignal_Image = cell.imageView.image
                    self.userName.text = postObj.owner.fullName
                    self.profilePic.file = postObj.owner.image
                    self.profilePic.loadInBackground()
                }
                else    {
                    cell.imageView.image = imageToBePresented
                }
            }
            
            if (self.flipsArray != nil)  {
                if (self.flipsArray.count > 0)  {
                    if (indexPath.row == 0) {
                        
                    }
                    else    {
                        var myObject: FlipsObject = self.flipsArray.objectAtIndex(indexPath.row-1) as! FlipsObject
                        cell.imageView.file = myObject.image
                        cell.imageView.loadInBackground({ (image :UIImage?, error :NSError?) -> Void in
                            cell.imageView.frame = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height)
                            cell.imageView.contentMode = UIViewContentMode.ScaleAspectFit
                            cell.imageView.clipsToBounds = true
                            cell.imageView.image = image
                            
                        }) //loadInBackground()
                        /*
                        self.userName.text = postObj.owner.fullName
                        self.profilePic.file = postObj.owner.image
                        */
                        // CHANGED BY CLIENT -> Only show name of owner ^^^
                        
                        self.profilePic.file = myObject.flipper.image
                        self.userName.text = myObject.flipper.fullName
                        
                        self.profilePic.loadInBackground()
                    }
                }
            }
            else if (postObj != nil) {
//                cell.imageView.image = UIImage(named: "user_upload_img.png")
                cell.imageView.image = self.fullScreenImage.image
            }
        }
//        cell.contentMode = UIViewContentMode.ScaleAspectFill
//        cell.clipsToBounds = true
//        cell.imageView.frame.size = cell.frame.size
//        cell.imageView.contentMode = UIViewContentMode.ScaleAspectFill
//        cell.imageView.clipsToBounds = true
        
//        }
        
        return cell;
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int  {
        return 1
    }
    
    // MARK: - CollectionView delegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)  {
//        NOTIFY.postNotificationName(NOTIF_CELL_IMAGE_BUTTON_CLICKED, object: nil, userInfo:["tag" : collectionView.tag, "indexPath" : indexPath])
    }

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        var index = Int(self.myCollectionView.contentOffset.x/self.myCollectionView.frame.size.width)
        indexLocation = NSIndexPath(forItem: index, inSection: 0)
        NSLog("indexLocation = %d", indexLocation.row)
        
        self.profilePic.image = UIImage(named: "user_upload_img.png")
        self.userName.text = " "
        
        if (notifMode == true)  {
            
            /*if (self.flipsArray != nil)  {
                if (indexLocation.row == self.flipsArray.count) {
                        self.userName.text = postObj.owner.fullName
                        self.profilePic.file = postObj.owner.image
                        self.profilePic.loadInBackground()
                }
            }
            else   {
                
            }*/
            
            // CHANGED BY CLIENT -> Only show name of owner ^^^
            
            if (self.flipsArray != nil)  {
                if (self.flipsArray.count > 0)  {
                    if (indexLocation.row == self.flipsArray.count) {
                        self.userName.text = postObj.owner.fullName
                        self.profilePic.file = postObj.owner.image
                        self.profilePic.loadInBackground()
                    }
                    else    {
                        var myObject: FlipsObject = self.flipsArray.objectAtIndex(indexLocation.row) as! FlipsObject
                        self.profilePic.file = myObject.flipper.image
                        self.userName.text = myObject.flipper.fullName
                        self.profilePic.loadInBackground()
                    }
                }
            }
            else if (postObj != nil) {
                self.userName.text = postObj.owner.fullName
                self.profilePic.file = postObj.owner.image
                self.profilePic.loadInBackground()
            }
            
        }
        else    {
            /*
            if (postObj != nil)  {
                self.userName.text = postObj.owner.fullName
                self.profilePic.file = postObj.owner.image
                self.profilePic.loadInBackground()
            }
            else    {
                
            }*/
            
            
            // CHANGED BY CLIENT -> Only show name of owner ^^^
            
            if (indexLocation.row == 0) {
                if (postObj != nil)  {
                    self.userName.text = postObj.owner.fullName
                    self.profilePic.file = postObj.owner.image
                    self.profilePic.loadInBackground()
                }
                else    {
                    
                }
            }
            
            if (self.flipsArray != nil)  {
                if (self.flipsArray.count > 0)  {
                    if (indexLocation.row == 0) {
                        
                    }
                    else    {
                        var myObject: FlipsObject = self.flipsArray.objectAtIndex(index-1) as! FlipsObject
                        self.profilePic.file = myObject.flipper.image
                        self.userName.text = myObject.flipper.fullName
                        self.profilePic.loadInBackground()
                    }
                }
            }
            
        }
        
        self.pageController.currentPage = indexLocation.row
        
        if let cell_col: CollectionViewCell = (self.myCollectionView.cellForItemAtIndexPath(indexLocation) as? CollectionViewCell)  {
            self.fullScreenImage.image = cell_col.imageView.image
        }
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

