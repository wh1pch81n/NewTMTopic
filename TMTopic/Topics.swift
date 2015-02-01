//
//  Topics.swift
//  TMTopic
//
//  Created by Derrick  Ho on 1/31/15.
//  Copyright (c) 2015 dnthome. All rights reserved.
//

import Foundation
import CoreData

@objc(Topics)
class Topics: NSManagedObject {

    @NSManaged var intro: String
    @NSManaged var max: NSNumber
    @NSManaged var min: NSNumber
    @NSManaged var question: String
    @NSManaged var batch: Batch
    @NSManaged var category: Category
    @NSManaged var source: Source

}
