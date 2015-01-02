//
//  TMNetworkInterface.swift
//  TMTopic
//
//  Created by Derrick Ho on 11/9/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

import Foundation

public let TMNetworkInterfaceDidFetchNotification = "TMNetworkInterfaceDidFetchNotification"

private let _firstLevelBatchPListURL = "https://raw.githubusercontent.com/wh1pch81n/NewTMTopic_Data/master/firstLevelBatch.plist"
private let _TMNetworkInterfaceSingletonInstance = TMNetworkInterface()

class TMNetworkInterface : NSObject {
    class var sharedInstance : TMNetworkInterface {
        return _TMNetworkInterfaceSingletonInstance
    }
    
    var urlSession = NSURLSession.sharedSession()
    var notificationCenter = NSNotificationCenter.defaultCenter()
    
    func checkForUpdate() {
        self.urlSession.dataTaskWithURL(NSURL(string: _firstLevelBatchPListURL)!, completionHandler: { (data : NSData!, response: NSURLResponse!, error : NSError!) -> Void in
            if error != nil {
                return
            }
            var batch = NSPropertyListSerialization.propertyListWithData(data, options: NSPropertyListReadOptions(), format: nil, error: nil) as? NSArray
            if let b = batch {
                for i in b {
                    var batchURL = i["batchUrl"] as NSString
                    self.urlSession.dataTaskWithURL(NSURL(string: batchURL)!, completionHandler: { (data, response, error) -> Void in
                        if error != nil {
                            return;
                        }
                        var topics = NSPropertyListSerialization.propertyListWithData(data, options: NSPropertyListReadOptions(), format: nil, error: nil) as? NSArray
                        if let a = topics {
                            var d = NSMutableDictionary()
                            d["batchDate"] = i["batchDate"]
                            d["topics"] = a
                            self.notificationCenter.postNotificationName(TMNetworkInterfaceDidFetchNotification, object: self, userInfo: d)
                        }
                    }).resume()
                }
            }
            
            //for each date in array go to each url and get its topic
            ////for each topic send a notification with the topic - date pair /*the listener should decide if it should save these values or not*/
        }).resume()
        
    }
    
    //TODO: make a checkForUpdate that will only send a notification if there is a need to go past the first level.
}
