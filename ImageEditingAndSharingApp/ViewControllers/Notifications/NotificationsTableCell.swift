//
//  NotificationsTableCell.swift
//  FlipCast
//
//  Created by Usman Shahid on 15/06/2015.
//  Copyright (c) 2015 Granjur. All rights reserved.
//

import UIKit
import Parse

class NotificationsTableCell: PFTableViewCell, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var flipObjID   : String!
    var flipsArray  : NSMutableArray!
    var orignal_Image_file   : PFFile!   // orignal_Image_file
    var orignal_Image : UIImage!
    
    // MARK: - OUTLETS
    @IBOutlet weak var myCollectionView: UICollectionView!
    @IBOutlet weak var profilePic: UIButton!
    @IBOutlet weak var profilePicView: PFImageView!
    
    @IBOutlet weak var flippedImg1: UIButton!
    @IBOutlet weak var flippedImg2: UIButton!
    @IBOutlet weak var flippedImg3: UIButton!
    @IBOutlet weak var flippedImgView1: PFImageView!
    @IBOutlet weak var flippedImgView2: PFImageView!
    @IBOutlet weak var flippedImgView3: PFImageView!
    
    
    @IBOutlet weak var nameText: UILabel!
    @IBOutlet weak var flipsText: UILabel!
    
    @IBOutlet weak var timeElapsed: UILabel!
    
    @IBOutlet weak var favoritiesButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var refreshButton: UIButton!
    
    @IBOutlet weak var likesCount: UILabel!
    
    // MARK: - DEFAULT
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        NOTIFY.addObserver(self, selector: "reloadCollectionView:", name:RELOAD_FLIPS, object: nil)
        
        flipsArray = nil
        
        profilePicView.clipsToBounds = true
        profilePicView.layer.cornerRadius = profilePicView.frame.size.width/2.0
        profilePicView.layer.borderWidth = 2.0
        profilePicView.contentMode = UIViewContentMode.ScaleAspectFill
        var myColor : UIColor = UIColor(red: 112/255, green: 102/255, blue: 110/255, alpha: 1)
        profilePicView.layer.borderColor = myColor.CGColor
        
        self.myCollectionView.delegate = self
        self.myCollectionView.dataSource = self
        self.myCollectionView!.registerClass(PFCollectionViewCell.self, forCellWithReuseIdentifier: "PFCollectionViewCell")
        
        var actInd: UIActivityIndicatorView = UIActivityIndicatorView()
        actInd.frame = CGRectMake(0.0, 0.0, 20.0, 20.0);
        //        actInd.transform = CGAffineTransformMakeScale(1.5 , 1.5);
        actInd.center = CGPointMake(self.profilePicView.frame.size.width/2.0, self.profilePicView.frame.size.height/2.0)
        actInd.hidesWhenStopped = true
        actInd.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        actInd.tag = 100;
        actInd.startAnimating()
        self.profilePicView.addSubview(actInd)
        self.profilePicView.bringSubviewToFront(actInd)
        
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    // MARK: - BUTTON ACTIONS
    @IBAction func profilePicClicked(sender: AnyObject) {
        println("profilePicClicked")
        //    var selectedDateDictionary = ["birthDate" : dateOfBirthPicker.date]
        NOTIFY.postNotificationName(NOTIF_CELL_IMAGE_BUTTON_CLICKED, object: nil, userInfo:["tag" : sender.tag])
    }
    
    @IBAction func flippedImg1Clicked(sender: AnyObject) {
        println("flippedImg1Clicked")
        flippedImg1.setBackgroundImage(flippedImgView1.image, forState: UIControlState.Normal)
        NOTIFY.postNotificationName(NOTIF_CELL_IMAGE_BUTTON_CLICKED, object: nil, userInfo:["tag" : sender.tag])
    }
    @IBAction func flippedImg2Clicked(sender: AnyObject) {
        println("flippedImg2Clicked")
        //        NOTIFY.postNotificationName(NOTIF_CELL_IMAGE_BUTTON_CLICKED, object: nil, userInfo:["tag" : sender.tag])
    }
    @IBAction func flippedImg3Clicked(sender: AnyObject) {
        println("flippedImg3Clicked")
        //        NOTIFY.postNotificationName(NOTIF_CELL_IMAGE_BUTTON_CLICKED, object: nil, userInfo:["tag" : sender.tag])
    }
    
    @IBAction func favoritiesButtonClicked(sender: AnyObject) {
        println("favoritiesButtonClicked")
        NOTIFY.postNotificationName(NOTIF_CELL_IMAGE_BUTTON_CLICKED, object: nil, userInfo:["tag" : sender.tag])
    }
    @IBAction func likeButtonClicked(sender: AnyObject) {
        println("likeButtonClicked")
        NOTIFY.postNotificationName(NOTIF_CELL_IMAGE_BUTTON_CLICKED, object: nil, userInfo:["tag" : sender.tag])
    }
    @IBAction func shareButtonClicked(sender: AnyObject) {
        println("shareButtonClicked")
        NOTIFY.postNotificationName(NOTIF_CELL_IMAGE_BUTTON_CLICKED, object: nil, userInfo:["tag" : sender.tag, "shareImg": screenShotMethod()])
        
    }
    @IBAction func refreshButtonClicked(sender: AnyObject) {
        println("refreshButtonClicked")
        NOTIFY.postNotificationName(NOTIF_CELL_IMAGE_BUTTON_CLICKED, object: nil, userInfo:["tag" : sender.tag])
    }
    
    
    // MARK: - COLLECTION VIEW
    
    // MARK: - CollectionView data source
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int   {
        if (self.flipsArray != nil) {
            //            NSLog("self.flipsArray.count = %d", self.flipsArray.count)
            return self.flipsArray.count+1  // 1 is original image and other are flips
        }
        else    {
            return 1
        }
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PFCollectionViewCell", forIndexPath: indexPath) as! PFCollectionViewCell
        //        if (indexPath.row > 0)  {
        // Load profile pic
        cell.imageView.image = UIImage(named: "loader.png")
        cell.imageView.clipsToBounds = true
        cell.imageView.contentMode = UIViewContentMode.ScaleAspectFit
        
        if (self.flipsArray != nil)  {
            if (self.flipsArray.count > 0)  {
                if (indexPath.row == self.flipsArray.count) {
                    cell.imageView.file = orignal_Image_file
                    cell.imageView.loadInBackground()
                    orignal_Image = cell.imageView.image
                }
                else    {
                    var myObject: FlipsObject = self.flipsArray.objectAtIndex(indexPath.row) as! FlipsObject
                    cell.imageView.file = myObject.image
                    cell.imageView.loadInBackground()
                }
            }
        }
        else    {
            if (indexPath.row == 0) {
                //                    var myObject: FlipsObject = self.flipsArray.objectAtIndex(0) as! FlipsObject
                cell.imageView.file = orignal_Image_file
                cell.imageView.loadInBackground()
                orignal_Image = cell.imageView.image
            }
        }
        
        return cell;
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int  {
        return 1
    }
    
    // MARK: - CollectionView delegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)  {
        NOTIFY.postNotificationName(NOTIF_CELL_IMAGE_BUTTON_CLICKED, object: nil, userInfo:["tag" : collectionView.tag, "indexPath" : indexPath, "flipsArray" : self.flipsArray, "orignal_Image_file": self.orignal_Image_file])
    }
    
    
    // MARK: - NOTIFICATIONS
    
    func reloadCollectionView(notification: NSNotification){
        var obj = notification.userInfo!["FlipsArray"] as! NSMutableArray
        NSLog("obj = %@", obj)
        
        //        self.flipsArray = obj
        //        self.myCollectionView.reloadData()
    }
    
    // MARK: - SCREENSHOT
    func screenShotMethod() -> UIImage {
        let layer = self.layer
        let scale = UIScreen.mainScreen().scale
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
        
        layer.renderInContext(UIGraphicsGetCurrentContext())
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return screenshot
    }
}
