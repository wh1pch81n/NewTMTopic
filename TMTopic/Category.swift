//
//  Category.swift
//  TMTopic
//
//  Created by Derrick  Ho on 1/31/15.
//  Copyright (c) 2015 dnthome. All rights reserved.
//

import Foundation
import CoreData

@objc(Catagory)
class Category: NSManagedObject {

    @NSManaged var category: String
    @NSManaged var topics: NSSet

}
