//
//  LoginVC.swift
//  FlipCast
//
//  Created by Granjur on 28/05/2015.
//  Copyright (c) 2015 Granjur. All rights reserved.
//

import UIKit
import Parse


class LoginVC: UIViewController {

    //MARK: - BUTTON ACTIONS
    
    @IBAction func SignUpClicked(sender: AnyObject) {
        let pushVc : SignUpVC = storyboard!.instantiateViewControllerWithIdentifier("SignUpVC") as! SignUpVC
        self.navigationController?.pushViewController(pushVc, animated: true)
    }
    
    @IBAction func SignInClicked(sender: AnyObject) {
        
        let pushVc : SignInVC = storyboard!.instantiateViewControllerWithIdentifier("SignInVC") as! SignInVC
        self.navigationController?.pushViewController(pushVc, animated: true)
    }
    
    @IBAction func facebookClicked(sender: AnyObject) {
        // Show activity indicator
        HELPER.showActivityIndicatory(self.view)
        
        let permissions = ["public_profile", "email", "user_friends"]
        PFFacebookUtils.logInInBackgroundWithReadPermissions(permissions) {
            (user: PFUser?, error: NSError?) -> Void in
            if let user = user {
                if user.isNew {
                    println("User signed up and logged in through Facebook!")
                    // Hide activity indicator
                    HELPER.stopActivityIndicator(self.view)
                    self.getDetailsAndSaveFB()
                    
                } else {
                    println("User logged in through Facebook!")
                    // Hide activity indicator
                    HELPER.stopActivityIndicator(self.view)
                    self.getDetailsAndSaveFB()
                }
            } else {
                println("The user cancelled the Facebook login.")
                // Hide activity indicator
                self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: "Cannot complete request", buttonTitle: "Ok"), animated: true, completion: nil)
                HELPER.stopActivityIndicator(self.view)
            }
        }
    }
    
    // MARK: - DEFAULT
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black;
        self.navigationController?.navigationBar.translucent = true
        
        if (DeviceType.IS_IPHONE_6)   {
            if let font = UIFont(name: "Lato-Semibold", size: 19.0*1.17) {
                self.navigationController!.navigationBar.titleTextAttributes = [ NSFontAttributeName: font,  NSForegroundColorAttributeName: UIColor.whiteColor()]
            }
        }
        if (DeviceType.IS_IPHONE_6P)   {
            if let font = UIFont(name: "Lato-Semibold", size: 19.0*1.3) {
                self.navigationController!.navigationBar.titleTextAttributes = [ NSFontAttributeName: font,  NSForegroundColorAttributeName: UIColor.whiteColor()]
            }
        }
        else    {
            if let font = UIFont(name: "Lato-Semibold", size: 19.0) {
                self.navigationController!.navigationBar.titleTextAttributes = [ NSFontAttributeName: font,  NSForegroundColorAttributeName: UIColor.whiteColor()]
            }
        }
        
        // Notification to recive reLogin request after password reset
        NOTIFY.addObserver(self, selector: "pushToLoginVC:", name:NOTIF_SIGNIN_AFTER_PSW_RESET, object: nil)
        NOTIFY.addObserver(self, selector: "showLandingPage:", name:NOTIF_SHOW_LANDING_PAGE, object: nil)
        
        HELPER.showActivityIndicatory(self.view)
        
        var currentUser = PFUser.currentUser()
        
        if currentUser != nil {
            println("ALREADY LOGGED IN");
            NOTIFY.postNotificationName(NOTIF_SHOW_LANDING_PAGE, object: nil)
            
        } else {
            // Show the signup or login screen
            
            // if it is not a PF User, we must check if user is linked with fb
//            let accessToken: FBSDKAccessToken = FBSDKAccessToken.currentAccessToken()
//            if let accessToken: FBSDKAccessToken = FBSDKAccessToken.currentAccessToken() {
//                println("accessToken = %@", accessToken)
//                PFFacebookUtils.logInInBackgroundWithAccessToken(accessToken, block: {
//                    (user: PFUser?, error: NSError?) -> Void in
//                    if user != nil {
//                        println("User logged in through Facebook!")
//                        SHARED.stopActivityIndicator(self.view)
//                    } else {
//                        println("Uh oh. There was an error logging in.")
//                        SHARED.stopActivityIndicator(self.view)
//                    }
//                })
//            }
//            else    {
//                SHARED.stopActivityIndicator(self.view)
//            }
            HELPER.stopActivityIndicator(self.view)
        }
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - CUSTOM ACTIONS
    
    func showLandingPage(notification: NSNotification)  {
        
        HELPER.stopActivityIndicator(self.view)
        
        var storyBoardName : String
        
        if DeviceType.IS_IPHONE_4_OR_LESS {
            storyBoardName = "LandingProfile4"
            println("IS_IPHONE_4")
        }
        else if DeviceType.IS_IPHONE_6 {
            storyBoardName = "LandingProfile6"
            println("IS_IPHONE_6")
        }
        else if DeviceType.IS_IPHONE_6P {
            storyBoardName = "LandingProfile6p"
            println("IS_IPHONE_6+")
        }
        else    {
            storyBoardName = "LandingProfile"
        }
        let storyboard = UIStoryboard(name: storyBoardName, bundle: NSBundle.mainBundle())
        let navVc : UINavigationController = storyboard.instantiateInitialViewController() as! UINavigationController
        
        APP_DELEGATE.window!.rootViewController = navVc
        
    }
    
    // MARK: - Notification
    func pushToLoginVC(notification: NSNotification){
        self.SignInClicked(UIButton())
    }
    
    // MARK: - FACEBOOK
    func getDetailsAndSaveFB ()
    {
        HELPER.showActivityIndicatory(self.view)
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: nil)
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            if ((error) != nil) {
                // Process error
                println("Error: \(error)")
                HELPER.stopActivityIndicator(self.view)
            }
            else    {
                HELPER.stopActivityIndicator(self.view)
                println("fetched user: \(result)")
                if let facebookID : NSString = result.valueForKey("id") as? NSString {
                    println("User FbId is: \(facebookID)")
                    PFUser.currentUser()!.setObject(facebookID, forKey: "fbid")
                } else {println("No facebookID fetched")}
                
                if let userName : NSString = result.valueForKey("name") as? NSString {
                    println("User Name is: \(userName)")
                }
                else    {
                    println("No username fetched")
                }
                
                if let userEmail : NSString = result.valueForKey("email") as? NSString {
                    println("User Email is: \(userEmail)")
                    PFUser.currentUser()!.setObject(userEmail, forKey: "email")
                }
                else  {
                    println("No email address fetched")
                }
                
                var facebookID: String = result.valueForKey("id") as! String
                var name: String = result.valueForKey("name") as! String
                PFUser.currentUser()!.setObject(name, forKey: _FULLNAME)
                PFUser.currentUser()!.setObject(name.lowercaseString, forKey: _CASE_INSEN_FN)
                
                var pictureURL = "https://graph.facebook.com/\(facebookID)/picture?type=large&return_ssl_resources=1"
                
                var URLRequest = NSURL(string: pictureURL)
                var URLRequestNeeded = NSURLRequest(URL: URLRequest!)
                
                NSURLConnection.sendAsynchronousRequest(URLRequestNeeded, queue: NSOperationQueue.mainQueue(), completionHandler: {(response: NSURLResponse!,data: NSData!, error: NSError!) -> Void in
                    if error == nil {
                        if (PFUser.currentUser()!.isNew) {
                            var picture = PFFile(data: data)
                            PFUser.currentUser()!.setObject(picture, forKey: _PICTURE)
                            let coverFile:PFFile = PFFile(data: UIImageJPEGRepresentation(UIImage(named: "cover.png"), 1.0))
                            PFUser.currentUser()!.setObject(coverFile, forKey: _COVER)
                            
                        }
                        PFUser.currentUser()!.saveInBackground()
                        
                        var user = PFUser.currentUser()
                        SHARED.userName     = user!.username!
                        SHARED.fullName     = user!.objectForKey(_FULLNAME) as! NSString
                        
                        if let userEmail : NSString = user!.valueForKey("email") as? NSString {
                            SHARED.emailAdress  = user!.email!
                        }
                        else    {
                            SHARED.emailAdress = ""
                        }
                        
                        SHARED.loggedIn     = true;
                        SHARED.saveUserData()
                        
                        NOTIFY.postNotificationName(NOTIF_SHOW_LANDING_PAGE, object: nil)
                    }
                    else {
                        println("Error: \(error.localizedDescription)")
                    }
                })
            }
        })
    }

    /* FOR CHECKING PERMISSION :P
    let facebookReadPermissions = ["public_profile", "email", "user_friends"]
    
    func loginToFacebookWithSuccess(successBlock: () -> (), andFailure failureBlock: (NSError?) -> ()) {
        
        if FBSDKAccessToken.currentAccessToken() != nil {
            //For debugging, when we want to ensure that facebook login always happens
            //FBSDKLoginManager().logOut()
            //Otherwise do:
//            return
        }
        
        FBSDKLoginManager().logInWithReadPermissions(self.facebookReadPermissions, handler: { (result:FBSDKLoginManagerLoginResult!, error:NSError!) -> Void in
            if error != nil {
                //According to Facebook:
                //Errors will rarely occur in the typical login flow because the login dialog
                //presented by Facebook via single sign on will guide the users to resolve any errors.
                
                // Process error
                FBSDKLoginManager().logOut()
                failureBlock(error)
            } else if result.isCancelled {
                // Handle cancellations
                FBSDKLoginManager().logOut()
                failureBlock(nil)
            } else {
                // If you ask for multiple permissions at once, you
                // should check if specific permissions missing
                
                if (result.grantedPermissions.contains("email"))    {
                    println("YES");
                }
//                for permission in self.facebookReadPermissions {
//                    if !contains("email", permission) {
//                        allPermsGranted = false
//                        break
//                    }
//                }
//                if allPermsGranted {
//                    // Do work
//                    let fbToken = result.token.tokenString
//                    let fbUserID = resutl.token.userID
//                    
//                    //Send fbToken and fbUserID to your web API for processing, or just hang on to that locally if needed
//                    //self.post("myserver/myendpoint", parameters: ["token": fbToken, "userID": fbUserId]) {(error: NSError?) ->() in
//                    //	if error != nil {
//                    //		failureBlock(error)
//                    //	} else {
//                    //		successBlock(maybeSomeInfoHere?)
//                    //	}
//                    //}
//                    
//                    successBlock()
//                } else {
//                    //The user did not grant all permissions requested
//                    //Discover which permissions are granted
//                    //and if you can live without the declined ones
//                    
//                }
            }
        })
    }*/
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
