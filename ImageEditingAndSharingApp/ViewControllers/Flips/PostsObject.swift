//
//  PostsObject.swift
//  FlipCast
//
//  Created by Usman Shahid on 17/06/2015.
//  Copyright (c) 2015 Granjur. All rights reserved.
//


import Foundation
import Parse

class PostsObject {
//    var isPrivate   : Bool              // Is private or public
    var owner       : FlipUser!         // owner creator
    var image       : PFFile!           // image
    var likes       : NSMutableArray!   // No of likes
    var favourities  : NSMutableArray!   // No of favorites
    var flips       : NSMutableArray!      // No of flips
    var postId      : String!           // postId
    var createdAt   : NSDate!           // Last Created
    var updatedAt   : NSDate!           // Last Updated
    
    init(dict: PFObject) {
        
        
        
//        self.isPrivate   = dict[_IS_PRIVATE]     as! Bool
        self.image       = dict[_IMAGE]          as! PFFile
        self.postId      = dict.objectId         as  String!
        self.createdAt   = dict.createdAt        as  NSDate!
        self.updatedAt   = dict.updatedAt        as  NSDate!
        
        if ((dict[_OWNER]) != nil)   {
            self.owner     = FlipUser(dict: dict[_OWNER] as! PFUser)
        }
        
        if ((dict[_LIKES]) != nil)  {
            self.likes       = dict[_LIKES] as! NSMutableArray
        }
        else    {
            self.likes       = NSMutableArray()
        }
        
        if ((dict[_FAVOURITIES]) != nil)  {
            self.favourities       = dict[_FAVOURITIES] as! NSMutableArray
        }
        else    {
            self.favourities       = NSMutableArray()
        }
        
        if ((flips) == nil)  {
            self.flips       = NSMutableArray()
        }
        self.update()
    }
    
    func getOwner() -> PFUser   {
        var user: PFUser = PFUser()
        user.objectId = owner.userId
        user[_PICTURE] = owner.image
        user[_COVER]    = owner.cover
        user[_FULLNAME] = owner.fullName
        
        return user
    }

    func update()    {
        var query = PFQuery(className:_FLIPS)
        query.includeKey(_OWNER)
        query.whereKey(_PARENT_ID, equalTo: postId)
        query.orderByDescending(_CREATED_AT)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                // The find succeeded.
                println("Successfully retrieved Flips against POST = \(objects!.count).")
                // Do something with the found objects
                if let objects = objects as? [PFObject] {
                    for object in objects {
                        var obj:FlipsObject = FlipsObject(dict: object)
                        self.flips.addObject(obj)
                    }
                    NOTIFY.postNotificationName(RELOAD_POSTS, object: nil, userInfo:["FlipsArray" : self.flips])
                }
                
            } else {
                let errorString = error!.userInfo?["error"] as? NSString
                NSLog("Errr loading flips of posts ")
            }
        }
    }
    
    
    
    convenience init() {
        var data: PFObject!
        self.init(
            dict: data
        )
    }
}
