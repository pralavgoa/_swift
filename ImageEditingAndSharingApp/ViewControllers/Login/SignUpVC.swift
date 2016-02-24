//
//  SignUpVC.swift
//  FlipCast
//
//  Created by Granjur on 28/05/2015.
//  Copyright (c) 2015 Granjur. All rights reserved.
//

import UIKit
import Parse
import AVFoundation
import Photos

class SignUpVC: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, CLLocationManagerDelegate {
    
    // MARK: - TAGS
    let FNAME_TAG = 1
    let EMAIL_TAG = 2
    let USERN_TAG = 3
    let PASSW_TAG = 4
    
    let picker = UIImagePickerController()

    // MARK: - PROPERTIES
    
    @IBOutlet var fullNameOutlet: UITextField!
    @IBOutlet var emailOutlet: UITextField!
    @IBOutlet var userNameOutlet: UITextField!
    @IBOutlet var passwordOutlet: UITextField!
    @IBOutlet weak var profilePicButton: UIButton!
    @IBOutlet var signUpButton: UIButton!

    // MARK: - ACTIONS
    
    @IBAction func uploadPicture(sender: AnyObject) {
        
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)){
            
            var actionSheet = UIActionSheet(title: "Choose a Picture Method", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Gallery", "Take Photo")
                actionSheet.showInView(self.view)
        }
        else    {
            HELPER.showAlertWithMessage("Error", alertMessage: "Camera Error", buttonTitle: "Ok")
        }
    }
    @IBAction func backButtonClicked(sender: AnyObject) {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    @IBAction func signUpClicked(sender: AnyObject) {
        
        var initialEmail = emailOutlet.text
        var email = initialEmail.lowercaseString
        var finalEmail = email.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        var user = PFUser()
        user.username = userNameOutlet.text
        user.password = passwordOutlet.text
        user.email = finalEmail
        
        // other fields can be set just like with PFObject
        user[_FULLNAME] = fullNameOutlet.text
        user[_CASE_INSEN_FN] = fullNameOutlet.text.lowercaseString
        
        let profileImage = self.profilePicButton.backgroundImageForState(UIControlState.Normal)
        let imageData = UIImageJPEGRepresentation(profileImage, 1.0)
        let imageFile:PFFile = PFFile(data: imageData)
        let coverFile:PFFile = PFFile(data: UIImageJPEGRepresentation(UIImage(named: "cover.png"), 1.0))
        user.setObject(imageFile, forKey: _PICTURE)
        user.setObject(coverFile, forKey: _COVER)
        
        HELPER.showActivityIndicatory(self.view)
        
        user.signUpInBackgroundWithBlock {
            (succeeded: Bool, error: NSError?) -> Void in
            if let error = error {
                HELPER.stopActivityIndicator(self.view)
                let errorString = error.userInfo?["error"] as? NSString
                // SHOW ERROR
                self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: errorString?.description, buttonTitle: "Ok"), animated: true, completion: nil)
            } else {
                println("// Hooray! Let them use the app now.")
                HELPER.stopActivityIndicator(self.view)
                
                var user = PFUser.currentUser()
                
                SHARED.userName     = user!.username!
                SHARED.fullName     = user!.objectForKey(_FULLNAME) as! NSString
                SHARED.emailAdress  = user!.email!
                SHARED.loggedIn     = true;
                SHARED.saveUserData()
                
                APP_DELEGATE.getAndUpdateUserLocation()
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.navigationController?.popToRootViewControllerAnimated(false)
                    NOTIFY.postNotificationName(NOTIF_SHOW_LANDING_PAGE, object: nil)
                })
            }
        }
    }
// MARK: - DEFAULTS
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set Delegates of TextFileds
        self.fullNameOutlet.delegate = self
        self.emailOutlet.delegate = self
        self.userNameOutlet.delegate = self
        self.passwordOutlet.delegate = self
        
        HELPER.resizeTextFields(self.fullNameOutlet)
        HELPER.resizeTextFields(self.emailOutlet)
        HELPER.resizeTextFields(self.userNameOutlet)
        HELPER.resizeTextFields(self.passwordOutlet)
        
        profilePicButton.clipsToBounds = true
        
        // Image picker
        self.picker.delegate = self
        signUpButton.enabled = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - TEXT FIELD DELEGATE
    
    func textFieldDidBeginEditing(textField: UITextField) {    //delegate method
        if (self.view.frame.origin.y < 0)   {
            HELPER.animateViewMoving(false, moveValue: 100, uiView: self.view, uiNav: self.navigationController!)
        }
        HELPER.animateViewMoving(true, moveValue: 100, uiView: self.view, uiNav: self.navigationController!)
        
//        if (textField.tag == FNAME_TAG) {
//        }
//        if (textField.tag == EMAIL_TAG) {
//        }
//        if (textField.tag == USERN_TAG) {
//        }
//        if (textField.tag == PASSW_TAG) {
//        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        
        HELPER.animateViewMoving(false, moveValue: 100, uiView: self.view, uiNav: self.navigationController!)
        
        if (textField.tag == FNAME_TAG) {
            println("textFieldShouldReturn = FNAME_TAG")
            // Automatically move to next text field
            emailOutlet.becomeFirstResponder();
        }
        if (textField.tag == EMAIL_TAG) {
            println("textFieldShouldReturn = EMAIL_TAG")
            if (!SHARED.isValidEmail(emailOutlet.text)) {
                self.presentViewController(HELPER.showAlertWithMessage("Invalid Email", alertMessage: "Please enter a valid Email address", buttonTitle: "Ok"), animated: true, completion: nil)
            }
            else    {
                userNameOutlet.becomeFirstResponder();
            }
        }
        if (textField.tag == USERN_TAG) {
            println("textFieldShouldReturn = USERN_TAG");
            passwordOutlet.becomeFirstResponder();
        }
        if (textField.tag == PASSW_TAG) {
            println("textFieldShouldReturn = PASSW_TAG");
        }
        
        if (fullNameOutlet.text.isEmpty || emailOutlet.text.isEmpty || userNameOutlet.text.isEmpty || passwordOutlet.text.isEmpty)  {
           signUpButton.enabled = false
        }
        else if (!SHARED.isValidEmail(emailOutlet.text)) {
            self.presentViewController(HELPER.showAlertWithMessage("Invalid Email", alertMessage: "Please enter a valid Email address", buttonTitle: "Ok"), animated: true, completion: nil)
            signUpButton.enabled = false
        }
        else    {
            signUpButton.enabled = true
        }
        
        return true
    }
    
    // MARK: - IMAGE PICKER DELEGATE
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject])    {
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            var chosenImage = info[UIImagePickerControllerEditedImage] as! UIImage
            self.profilePicButton.imageView!.contentMode = UIViewContentMode.ScaleAspectFill
            self.profilePicButton.setBackgroundImage(chosenImage, forState: UIControlState.Normal)
            self.profilePicButton.layer.cornerRadius = self.profilePicButton.frame.size.width/2.0
            self.profilePicButton.layer.borderWidth = 3.0
            var myColor : UIColor = UIColor(red: 112/255, green: 102/255, blue: 110/255, alpha: 1)
            self.profilePicButton.layer.borderColor = myColor.CGColor
        })
    }
    func imagePickerControllerDidCancel(picker: UIImagePickerController)   {
        dismissViewControllerAnimated(false, completion: nil)
    }
    
    // MARK: - ACTION SHEET DELEGATE
    // Called when a button is clicked. The view will be automatically dismissed after this call returns
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        
    }
    
    // Avoid presenting controller when action sheet is already dismissing
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int)   { // after animation
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
            
            if AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) ==  AVAuthorizationStatus.Authorized
            {
                // Already Authorized
                self.picker.allowsEditing = true
                self.picker.sourceType = .Camera
                self.presentViewController(picker, animated: true, completion: nil)
            }
            else
            {
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
    // Called when we cancel a view (eg. the user clicks the Home button). This is not called when the user clicks the cancel button.
    // If not defined in the delegate, we simulate a click in the cancel button
    func actionSheetCancel(actionSheet: UIActionSheet)  {
        
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
