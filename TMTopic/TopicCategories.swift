//
//  TopicCategories.swift
//  TMTopic
//
//  Created by Derrick  Ho on 12/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

import Foundation
import CoreData

@objc(TopicCategories)
class TopicCategories: NSManagedObject {

    @NSManaged var categories: String
    @NSManaged var batchTopics: NSSet

}
