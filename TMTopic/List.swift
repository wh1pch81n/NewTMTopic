//
//  List.swift
//  TMTopic
//
//  Created by Derrick  Ho on 1/31/15.
//  Copyright (c) 2015 dnthome. All rights reserved.
//

import Foundation
import CoreData

@objc(List)
class List: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var topics: NSSet

}
