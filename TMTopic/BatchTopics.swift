//
//  BatchTopics.swift
//  TMTopic
//
//  Created by Derrick  Ho on 12/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

import Foundation
import CoreData

@objc(BatchTopics)
class BatchTopics: NSManagedObject {

    @NSManaged var intro: String
    @NSManaged var max: NSNumber
    @NSManaged var min: NSNumber
    @NSManaged var question: String
    @NSManaged var batchDate: BatchDate
    @NSManaged var topicCategories: TopicCategories
    @NSManaged var topicSource: TopicSource

}
