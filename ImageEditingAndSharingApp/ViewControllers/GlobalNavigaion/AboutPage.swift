//
//  AboutPage.swift
//  FlipCast
//
//  Created by Usman Shahid on 08/06/2015.
//  Copyright (c) 2015 Granjur. All rights reserved.
//

import UIKit
import Parse
import AVFoundation
import Photos


class AboutPage: UIViewController {
    
    var animateView: Bool = false
    var isViewTransformed: Bool = false
    var FULL_BTN: UIButton!
    
    var mainText = "\nABOUT\n\n\nA fun & simple way to\ncommunicate creatively through photo & design\n\n\nA need for creative connection brought Flipcast to life. Social media has become so impossibly “ME” centric that likes and comments don’t make you feel like you are meaningfully engaging. But when every other medium and platform grows and thrives off collaboration, why aren’t we holding our photos to the same standards?\n\n\nThis community is for the people that find joy in creating with others, not just for themselves. For the people that think and create in more ways than just likes and words.\n\n\nThis community is not about the ME, but more importantly the WE.\n\nLet’s learn from each other.\nLet’s collaborate together.\nLet’s change our relationship with social media going forward.\n\nBe Inspired, Be Inspirational\n\n- The Flipcast Team"
    
    var titleText = "ABOUT"
    var subTitleText1 = "A fun & simple way to"
    var subTitleText2 = "communicate creatively through photo & design"
    var para1 = "A need for creative connection brought Flipcast to life. Social media has become so impossibly “ME” centric that likes and comments don’t make you feel like you are meaningfully engaging. But when every other medium and platform grows and thrives off collaboration, why aren’t we holding our photos to the same standards?"
    var para2 = "This community is for the people that find joy in creating with others, not just for themselves. For the people that think and create in more ways than just likes and words."
    var para3 = "This community is not about the ME, but more importantly the WE.\n\nLet’s learn from each other.\nLet’s collaborate together.\nLet’s change our relationship with social media going forward.\n\nBe Inspired, Be Inspirational\n\n- The Flipcast Team"
    
    var titleFName      = "Lato-Light"
    var subTitleFName1  = "Lato-Light"
    var subTitleFName2  = "Lato-Black"
    var paraFName       = "Lato-Light"
    
    var attributedString = NSMutableAttributedString()
    
    @IBOutlet weak var textF: UITextView!
    
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
    
    
    // MARK: - DEFAULTS
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        attributedString = NSMutableAttributedString(string:mainText)
        
        makeAttributedText(titleFName, fontColor: UIColor.whiteColor(), fontSize: 27.0, text: titleText)
        makeAttributedText(subTitleFName1, fontColor: UIColor.yellowColor(), fontSize: 20.0, text: subTitleText1)
        makeAttributedText(subTitleFName2, fontColor: UIColor.yellowColor(), fontSize: 20.0, text: subTitleText2)
        makeAttributedText(paraFName, fontColor: UIColor.lightGrayColor(), fontSize: 16.0, text: para1)
        makeAttributedText(paraFName, fontColor: UIColor.lightGrayColor(), fontSize: 16.0, text: para2)
        makeAttributedText(paraFName, fontColor: UIColor.lightGrayColor(), fontSize: 16.0, text: para3)
        
        self.textF.attributedText = attributedString
        
        FULL_BTN = UIButton(frame: self.view.frame)
        FULL_BTN.addTarget(self, action: "sideMenuClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        FULL_BTN.hidden = true
        self.view.addSubview(FULL_BTN)
        self.view.bringSubviewToFront(FULL_BTN)
    }
    
    func makeAttributedText(var fontName: String, var fontColor: UIColor, var fontSize: CGFloat, var text: String)  {
        if DeviceType.IS_IPHONE_6 { fontSize = fontSize*1.17  }
        else if DeviceType.IS_IPHONE_6P { fontSize = fontSize*1.3   }
        
        attributedString.addAttribute(NSForegroundColorAttributeName, value: fontColor , range: (mainText as NSString).rangeOfString(text))
        attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: fontName, size: fontSize)!, range: (mainText as NSString).rangeOfString(text))
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
    
        
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
