//
//  FlipUser.swift
//  FlipCast
//
//  Created by Usman Shahid on 17/06/2015.
//  Copyright (c) 2015 Granjur. All rights reserved.
//

import Foundation

import Foundation
import Parse

class FlipUser {
    var image       : PFFile!   // image
    var cover       : PFFile!   // cover photo
    var userId      : String!   // User ID
    var fullName    : String!   // Full Name
    
    init(dict: PFUser) {
        
        if (dict.objectId != nil)    {
            image       = dict[_PICTURE]    as! PFFile
            userId      = dict.objectId     as String!
            fullName    = dict[_FULLNAME]   as! String!
            if ((dict[_COVER]) != nil)  {
                cover       = dict[_COVER]  as! PFFile
            }
            
        }
    }
}
