//
//  ForgotPasswordVC.swift
//  FlipCast
//
//  Created by Usman Shahid on 08/06/2015.
//  Copyright (c) 2015 Granjur. All rights reserved.
//

import UIKit
import Parse

class ForgotPasswordVC: UIViewController, UITextFieldDelegate {

    // MARK: - Outlets
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var sendButton: UIButton!
    
    @IBOutlet weak var enterEmailText: UILabel!
    @IBOutlet weak var forgotPasswordText: UILabel!
    // MARK: - Button Actions
    
    @IBAction func sendEmailClicked(sender: AnyObject) {
        var initialEmail = emailTextField.text
        var email = initialEmail.lowercaseString
        var finalEmail = email.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        
        HELPER.showActivityIndicatory(self.view)
        
        PFUser.requestPasswordResetForEmailInBackground(finalEmail, block: { (success: Bool, error: NSError?) -> Void in
            if (error == nil) {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    HELPER.stopActivityIndicator(self.view)
                    
                    let vc : CheckEmailVC = self.storyboard!.instantiateViewControllerWithIdentifier("CheckEmailVC") as! CheckEmailVC
                    vc.emailID = finalEmail
                    self.presentViewController(vc, animated: false, completion: nil);
                    
                })
            }else {
                let errormessage = error!.userInfo?["error"] as? NSString
                self.presentViewController(HELPER.showAlertWithMessage("Cannot complete request", alertMessage: errormessage?.description, buttonTitle: "Ok"), animated: true, completion: nil)
                HELPER.stopActivityIndicator(self.view)
            }
        })
    }
    
    @IBAction func backButton(sender: AnyObject) {
        NOTIFY.removeObserver(self);
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: - Defaults
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sendButton.enabled = false
        self.emailTextField.delegate = self
        
        HELPER.resizeLabel(self.forgotPasswordText)
        HELPER.resizeLabel(self.enterEmailText)
        
        NOTIFY.addObserver(self, selector: "popToLoginVC:", name:NOTIF_LOGIN_PSW_RESET, object: nil)
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - TEXT FIELD DELEGATE
    
    func textFieldDidBeginEditing(textField: UITextField) {    //delegate method
        if (self.view.frame.origin.y < 0)   {
            HELPER.animateViewMoving(false, moveValue: 150, uiView: self.view, uiNav: self.navigationController!)
        }
        HELPER.animateViewMoving(true, moveValue: 150, uiView: self.view, uiNav: self.navigationController!)
        
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        
        HELPER.animateViewMoving(false, moveValue: 150, uiView: self.view, uiNav: self.navigationController!)
        
        
        if (emailTextField.text.isEmpty)  {
            sendButton.enabled = false
            self.presentViewController(HELPER.showAlertWithMessage("Invalid Email", alertMessage: "Please enter a valid Email address", buttonTitle: "Ok"), animated: true, completion: nil)
        }
        else if (!SHARED.isValidEmail(emailTextField.text))   {
            sendButton.enabled = false
            self.presentViewController(HELPER.showAlertWithMessage("Invalid Email", alertMessage: "Please enter a valid Email address", buttonTitle: "Ok"), animated: true, completion: nil)
        }
        else    {
            sendButton.enabled = true
        }
        
        return true
    }

    // MARK: - Notification
    func popToLoginVC(notification: NSNotification){
        
        NOTIFY.removeObserver(self);
        dispatch_async(dispatch_get_main_queue(), {
            self.navigationController?.popToRootViewControllerAnimated(false)
            NOTIFY.postNotificationName(NOTIF_SIGNIN_AFTER_PSW_RESET, object: nil)
        })
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
