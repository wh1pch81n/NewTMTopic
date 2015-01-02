//
//  TMTopicTableViewController.swift
//  TMTopic
//
//  Created by Derrick  Ho on 12/31/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

import UIKit
import CoreData

class TMTopicMasterTableViewController: UITableViewController {
    @IBOutlet weak var segmentControl: UISegmentedControl!
    private var currentFetchController : NSFetchedResultsController?
    private var lastSegmentIndex : Int = 0
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
    
    @IBAction func tappedSegmentController(sender: AnyObject) {
        self.tableView.reloadData()
    }
    
    //MARK: NSFetchedResultsController
    
    func fetchTopics() -> NSFetchedResultsController {
        if let cfc = self.currentFetchController {
            if self.lastSegmentIndex == self.segmentControl.selectedSegmentIndex {
                return cfc
            }
        }
        self.lastSegmentIndex = self.segmentControl.selectedSegmentIndex
        var fetchRequest = NSFetchRequest()
        self.tempContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        self.tempContext!.parentContext = Storage.sharedInstance.currentContext
        fetchRequest.entity = NSEntityDescription.entityForName("BatchTopics", inManagedObjectContext: self.tempContext!)
        fetchRequest.fetchBatchSize = 20
        var sortDescriptor : NSSortDescriptor?
        switch (self.lastSegmentIndex) {
        case 0: //Category
            sortDescriptor = NSSortDescriptor(key: "topicCategories", ascending: true)
        case 1: //Source
            sortDescriptor = NSSortDescriptor(key: "topicSource", ascending: true)
        case 2: //Date Added
            sortDescriptor = NSSortDescriptor(key: "batchDate", ascending: false)
        default:
            sortDescriptor = nil
        }
        if let sd = sortDescriptor {
            fetchRequest.sortDescriptors = [
                sd,
                NSSortDescriptor(key: "question", ascending: true)
            ]
        }
        var fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.tempContext!, sectionNameKeyPath: nil, cacheName: nil)
        var error : NSError?
        if fetchedResultsController.performFetch(&error) == false {
            abort() //fetch failed
        }
        self.currentFetchController = fetchedResultsController
        return self.currentFetchController!
    }
    
    //MARK: UITableViewController
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let s =  Storage.sharedInstance.fetchAllTopics().sections as? [NSFetchedResultsSectionInfo] {
            return s[section].numberOfObjects
        }
        return 0;
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
        var topic = fetchTopics().objectAtIndexPath(indexPath) as BatchTopics
        cell.textLabel?.text = topic.question
        cell.detailTextLabel?.text = "\(topic.topicSource.source) : \(topic.topicCategories.categories)"
        return cell;
    }
}

//class TMTopicDetailTableViewController : UITableViewController {
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateAvailable", name: StorageUpdatedNotification, object: nil)
//    }
//    
//    deinit {
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: StorageUpdatedNotification, object: nil)
//    }
//    
//    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        return 1
//    }
//    
//    
//}