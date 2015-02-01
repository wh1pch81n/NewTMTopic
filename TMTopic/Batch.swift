//
//  Batch.swift
//  TMTopic
//
//  Created by Derrick  Ho on 1/31/15.
//  Copyright (c) 2015 dnthome. All rights reserved.
//

import Foundation
import CoreData

@objc(Batch)
class Batch: NSManagedObject {

    @NSManaged var date: String
    @NSManaged var index: NSNumber
    @NSManaged var topics: NSSet

}
