//
//  BatchDate.swift
//  TMTopic
//
//  Created by Derrick  Ho on 12/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

import Foundation
import CoreData

@objc(BatchDate)
class BatchDate: NSManagedObject {

    @NSManaged var date: String
    @NSManaged var batchTopics: NSSet

}
