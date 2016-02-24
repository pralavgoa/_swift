//
//  CheckEmailVC.swift
//  FlipCast
//
//  Created by Usman Shahid on 08/06/2015.
//  Copyright (c) 2015 Granjur. All rights reserved.
//

import UIKit

class CheckEmailVC: UIViewController {

    // MARK: - OUTLETS
    
    var emailID = ""
    
    @IBOutlet weak var checkEmailText: UILabel!
    
    @IBOutlet weak var sendText: UILabel!
    @IBOutlet weak var resendText: UILabel!
    @IBOutlet weak var emailIDLabel: UILabel!
    
    // MARK: - BUTTON ACTIONS
    
    @IBAction func loginButtonClicked(sender: AnyObject) {
        self.dismissViewControllerAnimated(false, completion: nil)
        NOTIFY.postNotificationName(NOTIF_LOGIN_PSW_RESET, object: nil)
    }
    
    // MARK: - DEFAULTS
    override func viewDidLoad() {
        super.viewDidLoad()

        if (emailID.isEmpty)    {
            emailIDLabel.text = "Invalid Email ID"
        }
        else    {
            emailIDLabel.text = emailID
        }
        
        HELPER.resizeLabel(self.checkEmailText)
        HELPER.resizeLabel(self.resendText)
        HELPER.resizeLabel(self.emailIDLabel)
        HELPER.resizeLabel(self.sendText)
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
