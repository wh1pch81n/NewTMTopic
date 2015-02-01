//
//  StorageInterface.swift
//  TMTopic
//
//  Created by Derrick  Ho on 12/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

import Foundation
import CoreData

public let StorageUpdatedNotification = "StorageUpdatedNotification"

private let _storage = Storage()
class Storage : NSObject, TMNetworkInterfaceDelegate {
    class var sharedInstance: Storage {
        return _storage
    }
    
    var notificationCenter = NSNotificationCenter.defaultCenter()
    
    private var _managedObjectModel : NSManagedObjectModel
    private var _persistentStoreCoordinator : NSPersistentStoreCoordinator
    private var _managedObjectContext : NSManagedObjectContext
    internal var currentContext : NSManagedObjectContext {
        get {
            return _managedObjectContext
        }
    }
    
    override init() {
        var modelURL = NSBundle.mainBundle().URLForResource("storage", withExtension: "momd")
        _managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL!)!
        var directoryPath = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first as NSURL
        var storeURL = directoryPath
        storeURL = storeURL.URLByAppendingPathComponent("storage.sqlite")
        _persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: _managedObjectModel)
        var options = [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true]
        var error : NSError?;
        if let p = _persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options, error: &error) {
            _managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
            _managedObjectContext.persistentStoreCoordinator = _persistentStoreCoordinator
        } else {
            abort()//could not load persistent store
        }
        super.init()
    }
    
    func fetchEntity(entity : (name : String, sortDescriptor : NSSortDescriptor), predicate : NSPredicate?, context : NSManagedObjectContext) -> NSFetchedResultsController {
        var fetchRequest = NSFetchRequest()
        fetchRequest.entity = NSEntityDescription.entityForName(entity.name, inManagedObjectContext: context)
        fetchRequest.fetchBatchSize = 20;
        fetchRequest.sortDescriptors = [entity.sortDescriptor]
        fetchRequest.predicate = predicate
        var fetchedResultscontroller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        var error : NSError?
        if !fetchedResultscontroller.performFetch(&error) {
            abort() //fetch failed
        }
        return fetchedResultscontroller;
    }
    //TODO: Make more efficient by storing the fetch controller in a nscache with the date as the key.  Subscribe to the nsfetchedcontroller delegate and when update occurs you can simply clear the cache
    private func fetchBatchIndex(index : Int, context : NSManagedObjectContext) -> NSFetchedResultsController {
        return fetchEntity(
            (NSStringFromClass(Batch), NSSortDescriptor(key: "index", ascending: false)),
            predicate: NSPredicate(format: "index == %@", index),
            context: context)
    }
    
    private func fetchBatchDate(date : String, context : NSManagedObjectContext) -> NSFetchedResultsController {
        return fetchEntity(
            (NSStringFromClass(Batch), NSSortDescriptor(key: "date", ascending: false)),
            predicate: NSPredicate(format: "date == %@", date),
            context: context)
    }
    
    private func fetchCategoryName(name : String, context : NSManagedObjectContext) -> NSFetchedResultsController {
        return fetchEntity(
            (NSStringFromClass(Category), NSSortDescriptor(key: "category", ascending: true)),
            predicate: NSPredicate(format: "category == %@", name),
            context: context)
    }
    
    private func fetchSourcePath(path : String, context : NSManagedObjectContext) -> NSFetchedResultsController {
        return fetchEntity(
            (NSStringFromClass(Source), NSSortDescriptor(key: "source", ascending: true)),
            predicate: NSPredicate(format: "source == %@", path),
            context: context);
    }
    
    func fetchAllTopics() -> NSFetchedResultsController {
        return fetchEntity(
            (NSStringFromClass(Topics), NSSortDescriptor(key: "question", ascending: true)),
            predicate: nil,
            context: _managedObjectContext);
    }
    
    func errorGettingBatches(error : NSError) {
        // TODO: Needs implementing
    }
    
    func errorGettingTopics(error : NSError) {
        // TODO: Needs implementing
    }
    
    func currentBatches(batches : NSArray) {
        for batch in batches {
            var fetchedBatch = self.fetchBatchIndex(batchIndex, context: _managedObjectContext)
            // if batch["batchIndex"] doesn't exist, then add all the topics
            var batchIndex = batch["batchIndex"] as Int
            if fetchedBatch.fetchedObjects?.count == 0 {
                TMNetworkInterface.sharedInstance.getTopicsForBatch(batchIndex)
            } else if //let f fetchedBatch.fetchedObject { // else if batchIndex does exist but its date is differe, then update all topics of that batch index
                
            }
            
            // else the batch is the same as local.  No need to update/create
        }
    }
    
    func requestedTopics(topics : NSArray, batchIndex : Int, batchDate : String) {
        // Get instance of batch with index from CoreData
        // Translate the plist into core data stuff.
        var tempContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        tempContext.parentContext = _managedObjectContext;
//        let fetchedBatchIndex = self.fetchBatchIndex(Int(topicsContainer["batchIndex"]), context: tempContext)
//        let fetchedBatchIndex = self.fetchBatchIndex(topicsContainer["batchIndex"] as Int, context: tempContext)
//        if fetchedBatchIndex.fet.sections!.first!.numberOfObjects == 0 {
//            var batchDate = NSEntityDescription.insertNewObjectForEntityForName(NSStringFromClass(BatchDate), inManagedObjectContext: tempContext) as BatchDate
//            batchDate.date = userInfo["batchDate"] as NSString
//            for i in userInfo["topics"] as NSArray {
//                var batchTopic = NSEntityDescription.insertNewObjectForEntityForName(NSStringFromClass(BatchTopics), inManagedObjectContext: tempContext) as BatchTopics
//                batchTopic.batchDate = batchDate
//                if let category = i["category"] as? NSString {
//                    var topicCategory : TopicCategories
//                    let fetchedCategory = self.fetchCategoryName(category, context: tempContext)
//                    if fetchedCategory.sections!.first!.numberOfObjects == 0 {
//                        topicCategory = NSEntityDescription.insertNewObjectForEntityForName("TopicCategories", inManagedObjectContext: tempContext) as TopicCategories
//                        topicCategory.categories = category
//                    } else {
//                        topicCategory = fetchedCategory.fetchedObjects!.first as TopicCategories
//                    }
//                    batchTopic.topicCategories = topicCategory
//                }
//                if let source = i["source"] as? NSString {
//                    var topicSource : TopicSource
//                    let fetchedSource = self.fetchSourcePath(source, context: tempContext)
//                    if fetchedSource.sections!.first!.numberOfObjects == 0 {
//                        topicSource = (NSEntityDescription.insertNewObjectForEntityForName("TopicSource", inManagedObjectContext: tempContext) as TopicSource)
//                        topicSource.source = source
//                    } else {
//                        topicSource = fetchedSource.fetchedObjects!.first as TopicSource
//                    }
//                    batchTopic.topicSource = topicSource
//                }
//                batchTopic.intro = i["intro"] as NSString
//                var min : AnyObject? = i["min"]
//                if batchTopic.validateValue(&min, forKey: "min", error: nil) {
//                    batchTopic.min = i["min"] as Int
//                }
//                var max : AnyObject? = i["max"]
//                if batchTopic.validateValue(&max, forKey: "max", error: nil) {
//                    batchTopic.max = i["max"] as Int
//                }
//                batchTopic.question = i["question"] as NSString
//            }
//            
//            tempContext.performBlock({ () -> Void in
//                var error : NSError?
//                if !(tempContext.save(&error)) {
//                    abort()//could not save temp context
//                }
//                tempContext.parentContext!.performBlock({ () -> Void in
//                    var error : NSError?
//                    if !(tempContext.parentContext!.save(&error)) {
//                        abort()//could not save parent context
//                    }
//                    self.notificationCenter.postNotificationName(StorageUpdatedNotification, object: self)
//                })
//            })
//        }
    }
    
    //TODO: You should figure out a way to implicently delete batches.  you get a set of batch dates from the web and you have a local set of batch dates.  the web has priority and if the local has something that the web doesn't then it should try to delete that.  If the we has something that the local doesn't then the local should acquire it. If both have the same batch dates then you simply let it be.  that goes without saying that you should use the correct delete policy in the core data model interface so that it will delete all the topics and and whatnot
//    func recievedData(notification: NSNotification) {
//        var userInfo = notification.userInfo!
//        if userInfo.count == 0 { return }
//        var tempContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
//        tempContext.parentContext = _managedObjectContext;
//        let fetchedBatchDate = self.fetchBatchDate(userInfo["batchDate"] as String, context: tempContext)
//        if fetchedBatchDate.fetchedObjects?.count == 0 {
//            var batch = NSEntityDescription.insertNewObjectForEntityForName(NSStringFromClass(Batch), inManagedObjectContext: tempContext) as Batch
//            batch.index = te
//            batch.date = userInfo["batchDate"] as NSString
//            for i in userInfo["topics"] as NSArray {
//                var batchTopic = NSEntityDescription.insertNewObjectForEntityForName(NSStringFromClass(BatchTopics), inManagedObjectContext: tempContext) as BatchTopics
//                batchTopic.batchDate = batchDate
//                if let category = i["category"] as? NSString {
//                    var topicCategory : TopicCategories
//                    let fetchedCategory = self.fetchCategoryName(category, context: tempContext)
//                    if fetchedCategory.sections!.first!.numberOfObjects == 0 {
//                        topicCategory = NSEntityDescription.insertNewObjectForEntityForName("TopicCategories", inManagedObjectContext: tempContext) as TopicCategories
//                        topicCategory.categories = category
//                    } else {
//                        topicCategory = fetchedCategory.fetchedObjects!.first as TopicCategories
//                    }
//                    batchTopic.topicCategories = topicCategory
//                }
//                if let source = i["source"] as? NSString {
//                    var topicSource : TopicSource
//                    let fetchedSource = self.fetchSourcePath(source, context: tempContext)
//                    if fetchedSource.sections!.first!.numberOfObjects == 0 {
//                        topicSource = (NSEntityDescription.insertNewObjectForEntityForName("TopicSource", inManagedObjectContext: tempContext) as TopicSource)
//                        topicSource.source = source
//                    } else {
//                        topicSource = fetchedSource.fetchedObjects!.first as TopicSource
//                    }
//                    batchTopic.topicSource = topicSource
//                }
//                batchTopic.intro = i["intro"] as NSString
//                var min : AnyObject? = i["min"]
//                if batchTopic.validateValue(&min, forKey: "min", error: nil) {
//                    batchTopic.min = i["min"] as Int
//                }
//                var max : AnyObject? = i["max"]
//                if batchTopic.validateValue(&max, forKey: "max", error: nil) {
//                    batchTopic.max = i["max"] as Int
//                }
//                batchTopic.question = i["question"] as NSString
//            }
//            
//            tempContext.performBlock({ () -> Void in
//                var error : NSError?
//                if !(tempContext.save(&error)) {
//                    abort()//could not save temp context
//                }
//                tempContext.parentContext!.performBlock({ () -> Void in
//                    var error : NSError?
//                    if !(tempContext.parentContext!.save(&error)) {
//                        abort()//could not save parent context
//                    }
//                    self.notificationCenter.postNotificationName(StorageUpdatedNotification, object: self)
//                })
//            })
//        }
//    }
}