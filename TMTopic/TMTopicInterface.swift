//
//  TMTopicInterface.swift
//  TMTopic
//
//  Created by Derrick  Ho on 1/3/15.
//  Copyright (c) 2015 dnthome. All rights reserved.
//

import Foundation
import UIKit
import CoreData

enum TMTopicInterfaceOptions : Int {
  case NoOp = 0
  case Next
  case Prev
  case Random
  case TMTimer
}

private let kOffsetAmount : CGFloat = 50 //The minimum amount the UI has to move before an action is taken

class TMTopicInterface: UIViewController, UIScrollViewDelegate, NSFetchedResultsControllerDelegate {
    @IBOutlet weak var introLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var sourceTextView: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var topicView: UIView!
    var currentIndex = 0
    var currentLotteryMax = 0
    var _fetchedTopics: NSFetchedResultsController?
    var fetchedTopics: NSFetchedResultsController {
        get {
            if let ft = _fetchedTopics {
                return ft
            }
            var context = Storage.sharedInstance.currentContext
            var fetchedResults = NSFetchRequest()
            fetchedResults.entity = NSEntityDescription.entityForName(NSStringFromClass(BatchTopics), inManagedObjectContext: context)
            fetchedResults.fetchBatchSize = 20
            fetchedResults.sortDescriptors = [NSSortDescriptor(key: "question", ascending: true)]
//            fetchedResults.predicate //TODO: Only include the ones that are Marked in inclusion
            var fetchedController = NSFetchedResultsController(fetchRequest: fetchedResults, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            fetchedController.delegate = self
            var err : NSError?
            if !fetchedController.performFetch(&err) {
                abort() //Could not fetch
            }
            return fetchedController
        }
    }
    
    override func viewDidLoad() {
        scrollView.layer.masksToBounds = true
        scrollView.clipsToBounds = false
        chooseAction(TMTopicInterfaceOptions.Random)
    }
    
    //MARK: NSFetchedResultsControllerDelegate
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        _fetchedTopics = nil
        chooseAction(TMTopicInterfaceOptions.Random)
    }
    
    //MARK: UIScrollViewDelegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        //To prevent diagonal
        var dx = fabs(scrollView.contentOffset.x)
        var dy = fabs(scrollView.contentOffset.y)
        if dx >= dy {
            scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: 0)
        } else {
            scrollView.contentOffset = CGPoint(x: 0, y: scrollView.contentOffset.y)
        }
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        var dx = scrollView.contentOffset.x
        var dy = scrollView.contentOffset.y
        if fabs(dx) >= fabs(dy) {
            if dx > kOffsetAmount {
                chooseAction(.Next)
            } else if dx < -kOffsetAmount {
                chooseAction(.Prev)
            }
        } else {
            if dy > kOffsetAmount {
                chooseAction(.TMTimer)
            } else if dy < -kOffsetAmount {
                chooseAction(.Random)
            }
        }
    }
    
    func chooseAction(action : TMTopicInterfaceOptions) {
        var topics = fetchedTopics.fetchedObjects as [BatchTopics]
        currentLotteryMax = topics.count
        switch action {
        case .Next: currentIndex = (++currentIndex) % currentLotteryMax
        case .Prev: currentIndex = (--currentIndex + currentLotteryMax) % currentLotteryMax
        case .Random: currentIndex = Int(arc4random_uniform(UInt32(currentLotteryMax)))
        case .TMTimer:fallthrough
        default:
            ()
        }
        let topic = topics[currentIndex]
        updateUI(topic.intro, question: topic.question, category: topic.topicCategories.categories, source: topic.topicSource.source)
    }
    
    func updateUI(intro: String, question: String, category: String, source: String) {
        introLabel.text = intro
        questionLabel.text = question + "\n\n(\(currentIndex + 1) of \(currentLotteryMax))"
        sourceTextView.text = "Category: \(category)\nSource: \(source)"
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}