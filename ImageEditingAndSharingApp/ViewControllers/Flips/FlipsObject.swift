//
//  FlipsObject.swift
//  FlipCast
//
//  Created by Usman Shahid on 17/06/2015.
//  Copyright (c) 2015 Granjur. All rights reserved.
//


import Foundation
import Parse

class FlipsObject {
//    var isPrivate       : Bool      // Is private or public
    var flipper         : FlipUser!   // flipper creator
    var image           : PFFile!   // image
    var likes           : NSMutableArray! // No of likes
    var flipId          : String!   // FlipID
    var parentPostId    : String!   // Parent of the flip
    var createdAt       : NSDate!   // Last Created
    var updatedAt       : NSDate!   // Last Updated
    
    init(dict: PFObject) {
        
//        self.isPrivate       = dict[_IS_PRIVATE]     as! Bool
        self.image           = dict[_IMAGE]          as! PFFile
        self.parentPostId    = dict[_PARENT_ID]      as! String!
        self.flipId          = dict.objectId         as  String!
        self.createdAt       = dict.createdAt        as  NSDate!
        self.updatedAt       = dict.updatedAt        as  NSDate!
        
        
        if ((dict[_OWNER]) != nil)   {
            self.flipper     = FlipUser(dict: dict[_OWNER] as! PFUser)
        }
        if ((dict[_LIKES]) != nil)  {
            self.likes       = dict[_LIKES] as! NSMutableArray
        }
        else    {
            self.likes       = NSMutableArray()
        }
    }
    
    func getFlipper() -> PFUser   {
        var user: PFUser = PFUser()
        user.objectId   = flipper.userId
        user[_PICTURE]  = flipper.image
        user[_COVER]    = flipper.cover
        user[_FULLNAME] = flipper.fullName
        
        return user
    }

    convenience init() {
        var data: PFObject!
        self.init(
            dict: data
        )
    }
}
