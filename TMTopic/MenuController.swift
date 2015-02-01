//
//  MenuController.swift
//  TMTopic
//
//  Created by Derrick  Ho on 1/19/15.
//  Copyright (c) 2015 dnthome. All rights reserved.
//

import UIKit

private let kPlaylistIndexPath = NSIndexPath(forRow: 0, inSection: 0)

private let kRateAppIndexPath = NSIndexPath(forRow: 0, inSection: 1)
private let kSubmitTopicIndexPath = NSIndexPath(forRow: 1, inSection: 1)

class MenuController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.isEqual(kRateAppIndexPath) {
            iRate.sharedInstance().promptForRating()
        } else if indexPath.isEqual(kSubmitTopicIndexPath) {
            //Go to URL outside of app
        }
    }
}
