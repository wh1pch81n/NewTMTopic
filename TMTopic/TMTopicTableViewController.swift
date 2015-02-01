//
//  TMTopicTableViewController.swift
//  TMTopic
//
//  Created by Derrick  Ho on 12/31/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

import UIKit
import CoreData

enum TMTopicFilter : Int {
    case ByTopic = 0
    case ByCategory = 1
    case BySource = 2
}

class TMTopicMasterTableViewController: UITableViewController {
    @IBOutlet weak var segmentControl: UISegmentedControl!
    private var currentFetchController : NSFetchedResultsController?
    private var tempContext : NSManagedObjectContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateAvailable:", name: StorageUpdatedNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: StorageUpdatedNotification, object: nil)
    }
    
    func updateAvailable(notification : NSNotificationCenter) {
        tableView.reloadData()
    }
    
    @IBAction func tappedSegmentController(sender: AnyObject) {//TODO: Shouldn't this be value changed rather than touched?
        self.currentFetchController = nil
        self.tableView.reloadData()
    }
    
    //MARK: NSFetchedResultsController
    
    func fetchTopics() -> NSFetchedResultsController {
        if let cfc = self.currentFetchController {
            return cfc
        }
        var fetchRequest = NSFetchRequest()
        self.tempContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        self.tempContext!.parentContext = Storage.sharedInstance.currentContext
        fetchRequest.entity = NSEntityDescription.entityForName(NSStringFromClass(Topics), inManagedObjectContext: self.tempContext!)
        fetchRequest.fetchBatchSize = 20
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "question", ascending: true)]

        switch TMTopicFilter(rawValue: self.segmentControl.selectedSegmentIndex)! {
        case .ByCategory:
            fetchRequest.sortDescriptors!.insert(NSSortDescriptor(key: "Category", ascending: true), atIndex: 0)
        case .BySource:
            fetchRequest.sortDescriptors!.insert(NSSortDescriptor(key: "Source", ascending: true), atIndex: 0)
        default: ()
        }
        
        var fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.tempContext!, sectionNameKeyPath: nil, cacheName: nil)
        var error : NSError?
        if !fetchedResultsController.performFetch(&error) {
            abort() //fetch failed
        }
        self.currentFetchController = fetchedResultsController
        return self.currentFetchController!
    }
    
    //MARK: UITableViewController
    
    
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var entity : (String, NSSortDescriptor)
        var predicate : NSPredicate? //TODO: Leave for when search bar is added
        switch TMTopicFilter(rawValue: self.segmentControl.selectedSegmentIndex)! {
        case .ByTopic:
            return 1
        case .ByCategory:
            entity = (NSStringFromClass(Category), NSSortDescriptor(key: "category", ascending: true))
        case .BySource:
            entity = (NSStringFromClass(Source), NSSortDescriptor(key: "source", ascending: true))
        default:
            return 0
        }
        
        let context = Storage.sharedInstance.currentContext //TODO: This returns the maincontext, I feel like this should be a temp context once I start allowing customizations ie "playlists"
        return Storage.sharedInstance.fetchEntity(entity, predicate: predicate, context: context).sections!.first!.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRowsInSection : Int = 0
        let context = Storage.sharedInstance.currentContext //TODO: This returns the maincontext, I feel like this should be a temp context once I start allowing customizations ie "playlists"
        var entity : (String, NSSortDescriptor)
        var predicate : NSPredicate? //TODO: Leave for when search bar is added
        switch TMTopicFilter(rawValue: self.segmentControl.selectedSegmentIndex)! {
        case .ByTopic:
            entity = (NSStringFromClass(Topics), NSSortDescriptor(key: "question", ascending: true))
            if let fetched = Storage.sharedInstance.fetchEntity(entity, predicate: predicate, context: context).fetchedObjects as? [Topics] {
                numberOfRowsInSection = fetched.count
            }
        case .ByCategory:
            entity = (NSStringFromClass(Category), NSSortDescriptor(key: "category", ascending: true))
            if let fetched = Storage.sharedInstance.fetchEntity(entity, predicate: predicate, context: context).fetchedObjects as? [Category] {
                numberOfRowsInSection = fetched[section].topics.count
            }
        case .BySource:
            entity = (NSStringFromClass(Source), NSSortDescriptor(key: "source", ascending: true))
            if let fetched = Storage.sharedInstance.fetchEntity(entity, predicate: predicate, context: context).fetchedObjects as? [Source] {
                numberOfRowsInSection = fetched[section].topics.count
            }
        default: ()
        }
        return numberOfRowsInSection
    }
    //TODO: Add the auto resizing tableview cell based on content feature
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
        
        var offset = rowOffset(tableView, section: indexPath.section) 
        
        var topic = fetchTopics().objectAtIndexPath(NSIndexPath(forRow: indexPath.row + offset, inSection: 0)) as Topics
        cell.textLabel?.text = topic.question
        cell.detailTextLabel?.text = "\(topic.source.source) : \(topic.category.category)"
        return cell;
    }
    
    func rowOffset(tableView: UITableView, section: Int) -> Int {
        if section == 0 {
            return 0
        }
        return tableView.numberOfRowsInSection(section - 1) + rowOffset(tableView, section: (section - 1))
    }
    
    //TODO: Add Style and color to the sections to make them stand out
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title : String = ""
        let context = Storage.sharedInstance.currentContext //TODO: This returns the maincontext, I feel like this should be a temp context once I start allowing customizations ie "playlists"
        var entity : (String, NSSortDescriptor)
        var predicate : NSPredicate? = nil
        switch TMTopicFilter(rawValue: self.segmentControl.selectedSegmentIndex)! {
        
        case .ByCategory:
            entity = (NSStringFromClass(Category), NSSortDescriptor(key: "category", ascending: true))
            if let fetched = Storage.sharedInstance.fetchEntity(entity, predicate: predicate, context: context).fetchedObjects as? [Category] {
                title = "\(fetched[section].category) (\(fetched[section].topics.count) total)"
            }
        case .BySource:
            entity = (NSStringFromClass(Source), NSSortDescriptor(key: "source", ascending: true))
            if let fetched = Storage.sharedInstance.fetchEntity(entity, predicate: predicate, context: context).fetchedObjects as? [Source] {
                title = "\(fetched[section].source) (\(fetched[section].topics.count) total)"
            }
        case .ByTopic: fallthrough
        default:
            entity = (NSStringFromClass(Topics), NSSortDescriptor(key: "question", ascending: true))
            if let fetched = Storage.sharedInstance.fetchEntity(entity, predicate: predicate, context: context).fetchedObjects as? [Topics] {
                title = "All Topics (\(fetched.count) total)"
            }
        }
        return title
    }
}
