//
//  TMNetworkInterface.swift
//  TMTopic
//
//  Created by Derrick Ho on 11/9/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

import Foundation

private let _firstLevelBatchPListURL = "https://raw.githubusercontent.com/wh1pch81n/NewTMTopic_Data/master/firstLevelBatch.plist"

@objc protocol TMNetworkInterfaceDelegate {
    func currentBatches(batches : NSArray)
    func requestedTopics(topics : NSArray, batchIndex : Int, batchDate : String)
    
    func errorGettingBatches(error : NSError)
    func errorGettingTopics(error : NSError)
}

private let _TMNetworkInterfaceSingletonInstance = TMNetworkInterface()
class TMNetworkInterface : NSObject {
    class var sharedInstance : TMNetworkInterface {
        return _TMNetworkInterfaceSingletonInstance
    }
    
    var delegate : TMNetworkInterfaceDelegate?
    var urlSession = NSURLSession.sharedSession()
    var notificationCenter = NSNotificationCenter.defaultCenter()
    private var _batches : NSArray?
    
    func checkForBatchUpdate() {
        self.urlSession.dataTaskWithURL(NSURL(string: _firstLevelBatchPListURL)!, completionHandler: { (data : NSData!, response: NSURLResponse!, error : NSError!) -> Void in
            if error != nil {
                return
            }
            var batches = NSPropertyListSerialization.propertyListWithData(data, options: NSPropertyListReadOptions(), format: nil, error: nil) as? NSArray
            if let b = batches {
                self._batches = b
                let d = self.delegate
                if (d != nil) {
                    d!.currentBatches(b)
                } else {
                    var err = NSError()
                    d!.errorGettingTopics(err)
                }
            }
        }).resume()
    }
    
    func getTopicsForBatch(batchIndex : Int) {
        if let b = _batches {
            var batch = b[batchIndex] as NSDictionary
            self.urlSession.dataTaskWithURL(
                NSURL(string: batch["batchUrl"] as String)!,
                completionHandler: { (data, response, error) -> Void in
                    if error != nil {
                        return;
                    }
                    var topics = NSPropertyListSerialization.propertyListWithData(data, options: NSPropertyListReadOptions(), format: nil, error: nil) as? NSArray
                    if let t = topics {
                        let delegate = self.delegate
                        if delegate != nil {
                            var batchIndex = batch["batchIndex"] as Int
                            var batchDate = batch["batchDate"] as String
                            delegate?.requestedTopics(t, batchIndex:batchIndex, batchDate:batchDate)
                        } else {
                            var err = NSError()
                            delegate!.errorGettingTopics(err)
                        }
                    }
            }).resume()
        }
    }
}
