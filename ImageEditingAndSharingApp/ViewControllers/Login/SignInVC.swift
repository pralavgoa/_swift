//
//  SignInVC.swift
//  FlipCast
//
//  Created by Granjur on 28/05/2015.
//  Copyright (c) 2015 Granjur. All rights reserved.
//

import UIKit
import Parse

class SignInVC: UIViewController, UITextFieldDelegate {
    
    // MARK: - TAGS
    
    let USERN_TAG = 1
    let PASSW_TAG = 2

    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var signInButton: UIButton!
    // MARK: - ACTIONS
    
    @IBAction func backButtonClicked(sender: AnyObject) {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    @IBAction func signInClicked(sender: AnyObject) {
        
        // Show activity indicator
        HELPER.showActivityIndicatory(self.view)
        
        PFUser.logInWithUsernameInBackground(usernameTextField.text, password:passwordTextField.text) {
            (user: PFUser?, error: NSError?) -> Void in
            if user != nil {
                
                SHARED.userName     = user!.username!
                SHARED.fullName     = user!.objectForKey(_FULLNAME) as! NSString
                SHARED.emailAdress  = user!.email!
                SHARED.loggedIn     = true;
                SHARED.saveUserData()
                
                // Hide activity indicator
                HELPER.stopActivityIndicator(self.view)
                
                // Do stuff after successful login.
                println("HURRAH LOGGGED IN")
                
                APP_DELEGATE.getAndUpdateUserLocation()
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.navigationController?.popToRootViewControllerAnimated(false)
                    NOTIFY.postNotificationName(NOTIF_SHOW_LANDING_PAGE, object: nil)
                })
                
            } else if let error = error {
                // Hide activity indicator
                HELPER.stopActivityIndicator(self.view)
                
                let errorString = error.userInfo?["error"] as? NSString
                // SHOW ERROR
                self.presentViewController(HELPER.showAlertWithMessage("Error", alertMessage: errorString?.description, buttonTitle: "Ok"), animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func forgotPasswordClicked(sender: AnyObject) {
        let pushVc : ForgotPasswordVC = storyboard!.instantiateViewControllerWithIdentifier("ForgotPasswordVC") as! ForgotPasswordVC
        self.navigationController?.pushViewController(pushVc, animated: true)
    }
    
    
    // MARK: - DEFAULTS
    override func viewDidLoad() {
        super.viewDidLoad()

        usernameTextField.delegate = self
        passwordTextField.delegate = self
        
        HELPER.resizeTextFields(self.usernameTextField)
        HELPER.resizeTextFields(self.passwordTextField)
        
        signInButton.enabled = false
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - TEXT FIELD DELEGATE
    
    func textFieldDidBeginEditing(textField: UITextField) {    //delegate method
        
        if (textField.tag == USERN_TAG) {
        }
        if (textField.tag == PASSW_TAG) {
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        
        if (textField.tag == USERN_TAG) {
            // Automatically move to next text field
            passwordTextField.becomeFirstResponder();
        }
        if (textField.tag == PASSW_TAG) {
        }
        
        if (usernameTextField.text.isEmpty || passwordTextField.text.isEmpty)  {
            signInButton.enabled = false
        }
        else    {
            signInButton.enabled = true
        }
        
        return true
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
