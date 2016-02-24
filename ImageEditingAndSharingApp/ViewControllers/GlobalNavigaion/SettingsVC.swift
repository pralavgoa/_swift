//
//  SettingsVC.swift
//  FlipCast
//
//  Created by Usman Shahid on 10/06/2015.
//  Copyright (c) 2015 Granjur. All rights reserved.
//

import UIKit
import Parse
import AVFoundation
import Photos


class SettingsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate {

    var items: [String] = ["NOTIFICATIONS", "FLIP CENTRAL", "MY PROFILE", "INVITE FRIENDS", "ABOUT", "CONTACT"]
    let textCellIdentifier = "TextCell"
    let picker = UIImagePickerController()
    var CAMERA_TAG          = 1
    var SETTINGS_TAG        = 2
    var INVITE_FRIENDS_TAG  = 3
    var CURRENT_VC_TAG      = 100
    
    var landingPageVC   : LandingPage!
    var profilePageVC   : ProfilePage!
    var notificationsVC : NotificationsVC!
    var aboutPage       : AboutPage!
    
    // MARK: - OUTLETS
    
    @IBOutlet weak var slideView: UIView!
    @IBOutlet weak var overlayBg: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var profilePicOutlet: UIImageView!
    // MARK: - BUTTON ACTIONS
    
    @IBAction func settingsButtonClicked(sender: AnyObject) {
        var actionSheet = UIActionSheet(title: "Choose an Action", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "LOG OUT")
        actionSheet.tag = SETTINGS_TAG
        actionSheet.showInView(self.view)
    }
    
    @IBAction func cameraButtonClicked(sender: AnyObject) {
        
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)) {
            var actionSheet = UIActionSheet(title: "Choose a Picture Method", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Gallery", "Take Photo")
            actionSheet.tag = CAMERA_TAG
            actionSheet.showInView(self.view)
        }
        else{
            HELPER.showAlertWithMessage("Error", alertMessage: "Camera Error", buttonTitle: "Ok")
        }
    }
    
    // MARK: - DEFAULTS
    override func viewDidLoad() {
        super.viewDidLoad()

        NOTIFY.addObserver(self, selector: "slideViewLeft:", name:SLIDE_VIEW_LEFT, object: nil)
        NOTIFY.addObserver(self, selector: "alphaFactor:", name:ADJUST_OVERLAY_ALPHA, object: nil)
        NOTIFY.addObserver(self, selector: "showProfileForUserID:", name:NOTIF_SHOW_USER_PROFILE, object: nil)
        
        // Do any additional setup after loading the view.
        HELPER.resizeLabel(self.nameLabel)
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black;
        self.navigationController?.navigationBar.translucent = true
        
        self.navigationController?.navigationBar.hidden = true
        
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        
        let imageView = PFImageView()
        imageView.image = UIImage(named: "user_picture.png") // placeholder image
        
        self.picker.delegate = self
        HELPER.showActivityIndicatory(self.view)
        adjustAlpha(0.8, duration: 0.2)
        HELPER.resizeLabel(self.nameLabel)
        
        if (self.slideView.frame.origin.x != 0)  {
            var frame = self.slideView.frame
            frame.origin.x = 0.0
            self.slideView.frame = frame
        }
        HELPER.slideView(self.slideView, moveLeft: true, animationInterval: 1.0, timeDelay: 0, offsetFactor: self.slideView.frame.size.width)
        landingPageVC = storyboard!.instantiateViewControllerWithIdentifier("LandingPage") as! LandingPage
        landingPageVC.animateView = true
        landingPageVC.view.tag = CURRENT_VC_TAG
        self.view.addSubview(landingPageVC.view)
        self.view.bringSubviewToFront(landingPageVC.view)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - CUSTOM ACTIONS
    
    func loadUser() {
        var currentUser = PFUser.currentUser()
        if currentUser != nil {
            nameLabel.text  = SHARED.fullName as String
            if let userImageFile = currentUser?.objectForKey(_PICTURE) as? PFFile {
                userImageFile.getDataInBackgroundWithBlock({ (imageData: NSData?, error: NSError?) -> Void in
                    if error == nil {
                        if imageData != nil{
                            let image = UIImage(data:imageData!)
                            self.profilePicOutlet.image = image
                            self.profilePicOutlet.clipsToBounds = true
                            self.profilePicOutlet.layer.cornerRadius = self.profilePicOutlet.frame.size.width/2.0
                            self.profilePicOutlet.layer.borderWidth = 2.0
                            var myColor : UIColor = UIColor(red: 112/255, green: 102/255, blue: 110/255, alpha: 1)
                            self.profilePicOutlet.layer.borderColor = myColor.CGColor
                        }
                        // Hide activity indicator
                        HELPER.stopActivityIndicator(self.view)
                    }
                    else if let error = error {
                        // Hide activity indicator
                        HELPER.stopActivityIndicator(self.view)
                        
                        let errorString = error.userInfo?["error"] as? NSString
                        // SHOW ERROR
                        self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: errorString?.description, buttonTitle: "Ok"), animated: true, completion: nil)
                    }
                })
            }
        }
    }
    func removeCurrentView () {
        for view in self.view.subviews {
            if view.tag == CURRENT_VC_TAG {
                view.removeFromSuperview()
            }
        }
        // Make them nil
        self.landingPageVC = nil
        self.profilePageVC = nil
        self.notificationsVC = nil
        self.aboutPage = nil
    }
    
    func adjustAlpha (value: CGFloat, duration: NSTimeInterval) {
        UIView.animateWithDuration(duration, delay: 0.0, options: UIViewAnimationOptions.TransitionNone, animations: {
            self.overlayBg.alpha = value
            }, completion: { finished in
        })
        loadUser()
    }
    
    // MARK: - TABLVIEW DELEGATES
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count;
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(textCellIdentifier, forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel?.text = self.items[indexPath.row]
        var bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.clearColor()
        cell.selectedBackgroundView = bgColorView
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch (indexPath.row)    {
            case 0: // NOTIFICATIONS
                removeCurrentView()
                if (self.slideView.frame.origin.x != 0)  {
                    var frame = self.slideView.frame
                    frame.origin.x = 0.0
                    self.slideView.frame = frame
                }
                HELPER.slideView(self.slideView, moveLeft: true, animationInterval: 1.0, timeDelay: 0, offsetFactor: self.slideView.frame.size.width)
                adjustAlpha(0.8, duration: 0.2)
                notificationsVC = storyboard!.instantiateViewControllerWithIdentifier("NotificationsVC") as! NotificationsVC
                notificationsVC.animateView = true
                notificationsVC.user = nil
                notificationsVC.view.tag = CURRENT_VC_TAG
                self.view.addSubview(notificationsVC.view)
                self.view.bringSubviewToFront(notificationsVC.view)
            case 1: // FLIP CENTRAL
                removeCurrentView()
                if (self.slideView.frame.origin.x != 0)  {
                    var frame = self.slideView.frame
                    frame.origin.x = 0.0
                    self.slideView.frame = frame
                }
                HELPER.slideView(self.slideView, moveLeft: true, animationInterval: 1.0, timeDelay: 0, offsetFactor: self.slideView.frame.size.width)
                adjustAlpha(0.8, duration: 0.2)
                landingPageVC = storyboard!.instantiateViewControllerWithIdentifier("LandingPage") as! LandingPage
                landingPageVC.animateView = true
                landingPageVC.view.tag = CURRENT_VC_TAG
                self.view.addSubview(landingPageVC.view)
                self.view.bringSubviewToFront(landingPageVC.view)
            case 2: // PROFILE
                removeCurrentView()
                if (self.slideView.frame.origin.x != 0)  {
                    var frame = self.slideView.frame
                    frame.origin.x = 0.0
                    self.slideView.frame = frame
                }
                HELPER.slideView(self.slideView, moveLeft: true, animationInterval: 1.0, timeDelay: 0, offsetFactor: self.slideView.frame.size.width)
                adjustAlpha(0.8, duration: 0.2)
                profilePageVC = storyboard!.instantiateViewControllerWithIdentifier("ProfilePage") as! ProfilePage
                profilePageVC.user = nil
                profilePageVC.animateView = true
                profilePageVC.view.tag = CURRENT_VC_TAG
                self.view.addSubview(profilePageVC.view)
                self.view.bringSubviewToFront(profilePageVC.view)
            
            case 3: // INVITE FRIENDS
                var actionSheet = UIActionSheet(title: "Invite Friends", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "SMS", "EMAIL")
                actionSheet.tag = INVITE_FRIENDS_TAG
                actionSheet.showInView(self.view)
            case 4: // ABOUT
                removeCurrentView()
                HELPER.slideView(self.slideView, moveLeft: true, animationInterval: 1.0, timeDelay: 0, offsetFactor: self.slideView.frame.size.width)
                adjustAlpha(0.8, duration: 0.2)
                aboutPage = storyboard!.instantiateViewControllerWithIdentifier("AboutPage") as! AboutPage
                aboutPage.animateView = true
                aboutPage.view.tag = CURRENT_VC_TAG
                self.view.addSubview(aboutPage.view)
                self.view.bringSubviewToFront(aboutPage.view)
                
            case 5: // CONTACT
                APP_DELEGATE.sendEmail(CONTACT_EMAIL_TEXT, contact: true)
            default:
                println("You selected cell #\(indexPath.row)!")
        }
    }
    
    
    // MARK: - IMAGE PICKER DELEGATE
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject])    {
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            
            let profileImage = info[UIImagePickerControllerEditedImage] as! UIImage
            let imageData = UIImageJPEGRepresentation(profileImage, 1.0)
            let imageFile:PFFile = PFFile(data: imageData)
            PFUser.currentUser()!.setObject(imageFile, forKey: _PICTURE)
            
            HELPER.showActivityIndicatory(self.view)
            self.profilePicOutlet.layer.cornerRadius = self.profilePicOutlet.frame.size.width/2.0
            self.profilePicOutlet.layer.borderWidth = 3.0
            self.profilePicOutlet.contentMode = UIViewContentMode.ScaleAspectFill
            var myColor : UIColor = UIColor(red: 112/255, green: 102/255, blue: 110/255, alpha: 1)
            self.profilePicOutlet.layer.borderColor = myColor.CGColor
            
            PFUser.currentUser()!.saveInBackgroundWithBlock {
                (success: Bool, error: NSError?) -> Void in
                if (success) {
                    self.profilePicOutlet.image = profileImage
                    HELPER.stopActivityIndicator(self.view)
                    
                } else {
                    HELPER.stopActivityIndicator(self.view)
                    
                    let errorString = error!.userInfo?["error"] as? NSString
                    // SHOW ERROR
                    self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: errorString?.description, buttonTitle: "Ok"), animated: true, completion: nil)
                }
            }
            
        })
    }
    func imagePickerControllerDidCancel(picker: UIImagePickerController)   {
        dismissViewControllerAnimated(false, completion: nil)
    }
    
    // MARK: - ACTION SHEET DELEGATE
    
//    override func prefersStatusBarHidden() -> Bool {
//        return true
//    }
    
    // Called when a button is clicked. The view will be automatically dismissed after this call returns
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        
    }
    
    // Avoid presenting controller when action sheet is already dismissing
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int)   { // after animation
        
        if (actionSheet.tag == CAMERA_TAG)  {
            
            // GALARY
            if (buttonIndex == 1) {
                
                PHPhotoLibrary.requestAuthorization
                    { (PHAuthorizationStatus status) -> Void in
                        switch (status)
                        {
                        case .Authorized:
                            // Permission Granted
                            self.picker.allowsEditing = true
                            self.picker.sourceType = .PhotoLibrary
//                            self.prefersStatusBarHidden()
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
                    self.picker.allowsEditing = true
                    self.picker.sourceType = .Camera
                    self.presentViewController(picker, animated: true, completion: nil)
                }
                else    {
                    AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
                        if granted == true  {
                            // User granted
                            self.picker.allowsEditing = true
                            self.picker.sourceType = .Camera
                            self.presentViewController(self.picker, animated: true, completion: nil)
                        }
                        else    {
                            // User Rejected
                            self.presentViewController(HELPER.showAlertWithMessage("Permission", alertMessage: "You havn't granted permission to use camera", buttonTitle: "Ok"), animated: true, completion: nil)
                        }
                    });
                }
            }
        }
        else if (actionSheet.tag == SETTINGS_TAG)   {
            
            // LOG OUT
            if (buttonIndex == 1) {
                PFUser.logOut()
                SHARED.userName     = ""
                SHARED.fullName     = ""
                SHARED.emailAdress  = ""
                SHARED.loggedIn     = false;
                SHARED.user_loc     = ""
                SHARED.saveUserData()
                
                var storyBoardName : String
                
                if DeviceType.IS_IPHONE_4_OR_LESS {
                    storyBoardName = "Main4"
                    println("IS_IPHONE_4")
                }
                else    {
                    storyBoardName = "Main"
                }
                let storyboard = UIStoryboard(name: storyBoardName, bundle: NSBundle.mainBundle())
                let navVc : UINavigationController = storyboard.instantiateInitialViewController() as! UINavigationController
                APP_DELEGATE.window!.rootViewController = navVc
            }
        }
        else if (actionSheet.tag == INVITE_FRIENDS_TAG)   {
            
            // SMS
            if (buttonIndex == 1) {
                APP_DELEGATE.sendMessage(INVITE_FRIENDS_TEXT)
            }
            
            // EMAIL
            if (buttonIndex == 2) {
                APP_DELEGATE.sendEmail(INVITE_FRIENDS_TEXT, contact: false)
            }
        }
    }
    
    // MARK: - NOTIFICATIONS
    func alphaFactor(notification: NSNotification)  {
        adjustAlpha(0.0, duration: 0.5)
            var frame = self.slideView.frame
            frame.origin.x = -self.slideView.frame.size.width
            self.slideView.frame = frame
        HELPER.slideView(self.slideView, moveLeft: false, animationInterval: 0.75, timeDelay: 0, offsetFactor: self.slideView.frame.size.width*0.0)
    }
    
    func slideViewLeft(notification: NSNotification)  {
        if (self.slideView.frame.origin.x != 0)  {
            var frame = self.slideView.frame
            frame.origin.x = 0.0
            self.slideView.frame = frame
        }
        HELPER.slideView(self.slideView, moveLeft: true, animationInterval: 1.0, timeDelay: 0, offsetFactor: self.slideView.frame.size.width)
    }

    func showProfileForUserID(notification: NSNotification)  {
        
        var pfUser: PFUser = notification.userInfo!["user"] as! PFUser
        
        if (self.slideView.frame.origin.x != 0)  {
            var frame = self.slideView.frame
            frame.origin.x = 0.0
            self.slideView.frame = frame
        }
        HELPER.slideView(self.slideView, moveLeft: true, animationInterval: 1.0, timeDelay: 0, offsetFactor: self.slideView.frame.size.width)
        
        removeCurrentView()
        adjustAlpha(0.8, duration: 0.2)
        profilePageVC = storyboard!.instantiateViewControllerWithIdentifier("ProfilePage") as! ProfilePage
        profilePageVC.user = pfUser
        profilePageVC.animateView = true
        profilePageVC.view.tag = CURRENT_VC_TAG
        self.view.addSubview(profilePageVC.view)
        self.view.bringSubviewToFront(profilePageVC.view)
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
