//
//  AppDelegate.swift
//  FlipCast
//
//  Created by Granjur on 28/05/2015.
//  Copyright (c) 2015 Granjur. All rights reserved.
//

import UIKit
import Parse
import Photos
import MessageUI
import Social

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, FBSDKSharingDelegate, MFMailComposeViewControllerDelegate {

    var window: UIWindow?
    let messageComposer = MsgComposer()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        SHARED
        HELPER
        
        var storyBoardName : String
        
        if DeviceType.IS_IPHONE_4_OR_LESS {
            storyBoardName = "Main4"
            println("IS_IPHONE_4")
        }
        else    {
            storyBoardName = "Main"
        }
        let storyboard : UIStoryboard = UIStoryboard(name: storyBoardName, bundle: nil)
        let navVc : UINavigationController = storyboard.instantiateInitialViewController() as! UINavigationController
        self.window?.rootViewController = navVc
        
        // Test Fairy SDK
        TestFairy.begin("7707672fe4d61fe10c95d07f8b70dfd589f30a69")
        
        // PARSE LOGIN
        Parse.setApplicationId(PARSE_APP_ID,
            clientKey: PARSE_CLIENT_KEY)
        
        // link parse with Facebook
        PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions)
        
        // Override point for customization after application launch.
        
        AdobeUXAuthManager.sharedManager().setAuthenticationParametersWithClientID(ADOBE_CLIENT_ID, clientSecret:ADOBE_CLIENT_SECRET, enableSignUp: false)
        AdobeUXImageEditorViewController.inAppPurchaseManager().startObservingTransactions()
        AdobeImageEditorCustomization.setConfirmOnCancelEnabled(true)
        
        // Tools as per requirement
        AdobeImageEditorCustomization.setToolOrder([kAdobeImageEditorEffects, kAdobeImageEditorFrames, kAdobeImageEditorOverlay, kAdobeImageEditorStickers, kAdobeImageEditorCrop, kAdobeImageEditorDraw, kAdobeImageEditorText, kAdobeImageEditorMeme])
        
        // TIMER for saving user state = ACTIVE / LAST ACTIVE
        saveUserStateOnParse()
        var timer = NSTimer.scheduledTimerWithTimeInterval(30.0, target: self, selector:  Selector("saveUserStateOnParse"), userInfo: nil, repeats: true)
        
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
        
        return true
    }
    
    func application(application: UIApplication,
        openURL url: NSURL,
        sourceApplication: String?,
        annotation: AnyObject?) -> Bool {
            return FBSDKApplicationDelegate.sharedInstance().application(application,
                openURL: url,
                sourceApplication: sourceApplication,
                annotation: annotation)
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        FBSDKAppEvents.activateApp()
        getAndUpdateUserLocation()
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        SHARED.isAppActive = false
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        SHARED.isAppActive = true
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: - CUSTOM ACTIONS
    
    func shareIt ()   { // NOT USED
        
        let textToShare = EMAIL_BODY
        
        if let myWebsite = NSURL(string: "http://www.google.com/")  {
            let objectsToShare = [textToShare, myWebsite]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            
            //New Excluded Activities Code
            activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList, UIActivityTypePostToWeibo, UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypePostToFlickr, UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo, UIActivityTypePostToTwitter]
            //
            activityVC.completionHandler = {(activityType, completed:Bool) in
                if !completed {
                    println("cancelled")
                    return
                }
                if activityType == UIActivityTypePostToTwitter {
                    println("twitter")
                }
                if activityType == UIActivityTypeMail {
                    println("mail")
                }
            }
            APP_DELEGATE.window?.rootViewController!.presentViewController(activityVC, animated: true, completion: nil)
        }
    }
    
    func getAndUpdateUserLocation ()   {
        var location: PFGeoPoint!
        PFGeoPoint.geoPointForCurrentLocationInBackground {
            (geoPoint: PFGeoPoint?, error: NSError?) -> Void in
            if error == nil {
                // do something with the new geoPoint
                
                if ((PFUser.currentUser()) != nil)    {
                    PFUser.currentUser()!.setObject(geoPoint!, forKey: USER_LOCATION)
                    
                    let currentLocation = CLLocation(latitude: geoPoint!.latitude, longitude: geoPoint!.longitude)
                        CLGeocoder().reverseGeocodeLocation (currentLocation, completionHandler: {
                            placemarks, error in
                            
                            if error == nil && placemarks.count > 0 {
                                var placeMark = placemarks.last as? CLPlacemark
                                println("\(placeMark!.locality), \(placeMark!.country)")
                                SHARED.user_loc = "\(placeMark!.locality), \(placeMark!.country)"
                            }
                        })
                    PFUser.currentUser()!.saveInBackground()
                }
            }
        }
    }
    
    // MARK: - SCHEDULAR for updating user status
    
    func saveUserStateOnParse() {
        if (SHARED.isAppActive == true) {
            if (PFUser.currentUser() != nil) {
                PFUser.currentUser()!.setObject(true, forKey: FLIP_U_STATUS)
                PFUser.currentUser()!.saveInBackground()
            }
        }
    }
    
    // MARK: - SAVE IMAGES
    
    let albumName = "FlipCast"
    var albumFound : Bool = false
    var assetCollection: PHAssetCollection!
    var photosAsset: PHFetchResult!
    
    func saveToSpecialGalary (var image : UIImage)    {
        //Check if the folder exists, if not, create it
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collection:PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
        
        if let first_Obj:AnyObject = collection.firstObject {
            //found the album
            self.albumFound = true
            self.assetCollection = first_Obj as! PHAssetCollection
        }
        else{
            //Album placeholder for the asset collection, used to reference collection in completion handler
            var albumPlaceholder:PHObjectPlaceholder!
            //create the folder
            NSLog("\nFolder \"%@\" does not exist\nCreating now...", albumName)
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(self.albumName)
                albumPlaceholder = request.placeholderForCreatedAssetCollection
                },
                completionHandler: {(success:Bool, error:NSError!)in
                    if(success){
                        println("Successfully created folder")
                        self.albumFound = true
                        if let collection = PHAssetCollection.fetchAssetCollectionsWithLocalIdentifiers([albumPlaceholder.localIdentifier], options: nil)   {
                            self.assetCollection = collection.firstObject as! PHAssetCollection
                        }
                    }
                    else    {
                        println("Error creating folder")
                        self.albumFound = false
                    }
            })
        }
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0), {
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                let createAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(image)
                let assetPlaceholder = createAssetRequest.placeholderForCreatedAsset
                let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: self.assetCollection, assets: self.photosAsset)
                albumChangeRequest.addAssets([assetPlaceholder])
                }, completionHandler: {(success, error)in
                    dispatch_async(dispatch_get_main_queue(), {
                        self.window?.rootViewController?.presentViewController(HELPER.showAlertWithMessage("Image added to FlipCast Library", alertMessage: "", buttonTitle: "ok"), animated: false, completion: nil)
                    })
            })
        })
    }
    
    // MARK: - SOCIAL SHARING
    
    
    // MARK:- Facebook
    
    func sharer(sharer: FBSDKSharing!, didCompleteWithResults results: [NSObject : AnyObject]!) {
        NSLog("didCompleteWithResults")
    }
    
    func sharer(sharer: FBSDKSharing!, didFailWithError error: NSError!) {
        NSLog("didFailWithError")
    }
    
    func sharerDidCancel(sharer: FBSDKSharing!) {
        NSLog("didFailWithError")
    }
    
    func shareFBLink  (var url: NSURL)    {
        let content : FBSDKShareLinkContent = FBSDKShareLinkContent()
        content.contentURL = NSURL(string: "https://itunes.apple.com/us/app/flip-cast-free/id1017639934?ls=1&mt=8")
        content.contentTitle = "FlipCast"
        content.contentDescription = "Simpler way to Flips"
        content.imageURL = url
        
        let button : FBSDKShareButton = FBSDKShareButton()
        button.shareContent = content
        button.frame = CGRectMake(0, 0, 0, 0)
        button.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
    }
    
    func shareFBPhoto (var image: UIImage)  {
        
        if let appURL = NSURL(string: "fb://") {
            let canOpen = UIApplication.sharedApplication().canOpenURL(appURL)
            
            if (canOpen == true)    {
                println("FACEBOOK app available")
                let photo : FBSDKSharePhoto = FBSDKSharePhoto()
                photo.image = image
                photo.userGenerated = true
                let content : FBSDKSharePhotoContent = FBSDKSharePhotoContent()
                content.photos = [photo]
                let button:FBSDKShareButton = FBSDKShareButton()
                button.frame = CGRectMake(0, 0, 0, 0)
                button.shareContent = content
                button.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
            }
            else    {
//                if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook){
                    var facebookSheet:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
                    facebookSheet.setInitialText("")
                    facebookSheet.addImage(image)
                    self.window?.rootViewController!.presentViewController(facebookSheet, animated: true, completion: nil)
//                }
//                else {
//                    var alert = UIAlertController(title: "Accounts", message: "You must login your Facebook account through Settings or download facebook app", preferredStyle: UIAlertControllerStyle.Alert)
//                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
//                    self.window?.rootViewController!.presentViewController(alert, animated: true, completion: nil)
//                }
            }
        }
        
    }
    
    // MARK: - EMAIL
    
    func sendEmail(var text: String, var contact: Bool) {
        // contact -> if needs to contact the owner
        let mailComposeViewController = configuredMailComposeViewController()
        mailComposeViewController.setSubject("Flipcast")
        let model = UIDevice.currentDevice().model
        let osName = UIDevice.currentDevice().systemName
        let osVersion = UIDevice.currentDevice().systemVersion
        let countryCode = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode) as! String
        let countryName = NSLocale.currentLocale().displayNameForKey(NSLocaleCountryCode, value: countryCode)
        let region  = NSLocale.currentLocale().objectForKey(NSLocaleLanguageCode) as! String;
        let appName = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleDisplayName")  as! String
        let appId = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleIdentifier") as! String;
        let appVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String;
        let appBuild = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as! String;
        
        var diaData = String(format: "\n\n\n\n\n\n---------------------\nDETAILS:\n---------------------\nAppName = %@ \nAppID = %@ \nVersion = %@ \nBuild = %@ \nModel = %@ \nOS = %@ v = %@ \nRegion = %@ \nCountry = %@, %@", appName, appId, appVersion, appBuild, model, osName, osVersion, region, countryCode, countryName!)
        
        if (contact == true)    {
            mailComposeViewController.setToRecipients([CONTACT_EMAIL_ID])
        }
        else    {
            diaData = " "
        }
        var bodyString = String(format:"%@%@", text, diaData);
        mailComposeViewController.setMessageBody(bodyString, isHTML: false)
        
        if MFMailComposeViewController.canSendMail() {
            self.window?.rootViewController!.presentViewController(mailComposeViewController, animated: true, completion: nil)
        }
        else {
            self.showSendMailErrorAlert()
        }
    }
    
    func sendEmail_Image(var text: String, var image: UIImage) {
        
        let mailComposeViewController = configuredMailComposeViewController()
        mailComposeViewController.setSubject("Flipcast")
        
        mailComposeViewController.setMessageBody(text, isHTML: false)
        let imageData = UIImageJPEGRepresentation(image, 0.5)
        var fileName = "image"
        fileName.stringByAppendingPathExtension("jpeg")
        mailComposeViewController.addAttachmentData(imageData, mimeType: "image/jpeg", fileName: fileName)
        if MFMailComposeViewController.canSendMail() {
            self.window?.rootViewController!.presentViewController(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        return mailComposerVC
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
        sendMailErrorAlert.show()
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - SMS (MESSAGES)
    
    func sendMessage(var text: String) {
        
        // Make sure the device can send text messages
        if (messageComposer.canSendText()) {
            // Obtain a configured MFMessageComposeViewController
            let messageComposeVC = messageComposer.configuredMessageComposeViewController()
            messageComposeVC.body = text
            // Present the configured MFMessageComposeViewController instance
            // Note that the dismissal of the VC will be handled by the messageComposer instance,
            // since it implements the appropriate delegate call-back
            self.window?.rootViewController!.presentViewController(messageComposeVC, animated: true, completion: nil)
        }
        else {
            // Let the user know if his/her device isn't able to send text messages
            let errorAlert = UIAlertView(title: "Cannot Send Text Message", message: "Your device is not able to send text messages.", delegate: self, cancelButtonTitle: "OK")
            errorAlert.show()
        }
    }
    func sendMessage_Image(var text: String, var image: UIImage) {
        // Make sure the device can send text messages
        if (messageComposer.canSendText()) {
            // Obtain a configured MFMessageComposeViewController
            let messageComposeVC = messageComposer.configuredMessageComposeViewController()
            messageComposeVC.body = text
            let imageData = UIImageJPEGRepresentation(image, 0.5)
            var fileName = "image"
            fileName.stringByAppendingPathExtension("jpeg")
            messageComposeVC.addAttachmentData(imageData, typeIdentifier: "image/jpeg", filename: fileName)
            // Present the configured MFMessageComposeViewController instance
            self.window?.rootViewController!.presentViewController(messageComposeVC, animated: true, completion: nil)
        }
        else {
            // Let the user know if his/her device isn't able to send text messages
            let errorAlert = UIAlertView(title: "Cannot Send Text Message", message: "Your device is not able to send text messages.", delegate: self, cancelButtonTitle: "OK")
            errorAlert.show()
        }
    }

}

