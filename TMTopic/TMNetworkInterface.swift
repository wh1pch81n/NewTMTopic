//
//  TMNetworkInterface.swift
//  TMTopic
//
//  Created by Derrick Ho on 11/9/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

import Foundation

enum TMNetwork : Int {
    case processError = -2
    case fetchError = -1
    case fetchUnknown = 0
    case fetchSuccessful = 1
}

private let kFirstLevelXMLBatch = "";

public let TMNetworkInterfaceDidFetchNotification = "TMNetworkInterfaceDidFetchNotification"

class TMNetworkInterface : NSObject, NSXMLParserDelegate {
    var currentSession : NSURLSession = NSURLSession.sharedSession()
    var currentNotificationCenter : NSNotificationCenter = NSNotificationCenter.defaultCenter()
    var firstLevelXMLData : NSData?
    var firstLevelXMLDict, tempFirstLevelXMLDict : Dictionary<String, NSURL>?
    var secondLevelXMLDatas : Dictionary<NSURL, NSData>?
    
    class var sharedInstance : TMNetworkInterface {
        struct Static {
            static let _instance : TMNetworkInterface = TMNetworkInterface()
        }
        return Static._instance
    }
    
    func fetchFirstLevelXMLBatch (completionHandler: (TMNetwork) -> ()) {
        let url : NSURL = NSURL(string: kFirstLevelXMLBatch)!
        let urlRequest = NSURLRequest(URL: url)
        
        self.currentSession.dataTaskWithRequest(urlRequest,
            completionHandler: { (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
                if (error != nil) || (data == nil) {
                    //data error
                    completionHandler(TMNetwork.fetchError)
                    return;
                }
                self.firstLevelXMLData = data;
                var xmlparser = NSXMLParser(data: data);
                xmlparser.delegate = self
                if xmlparser.parse() == false {
                    self.firstLevelXMLDict = nil
                    completionHandler(TMNetwork.processError)
                    return
                }
                self.firstLevelXMLDict = self.tempFirstLevelXMLDict
                completionHandler(TMNetwork.fetchSuccessful)
        }).resume()
    }
    
    func fetchSecondLevelXML(completionHandler: (TMNetwork) -> ()) {
        //TODO: Think of name that is not 'batch' to call the elements of each file of topics
        if (firstLevelXMLDict != nil) {}
        else {
            completionHandler(TMNetwork.fetchError)
        }
        //TODO: for each XML batch, make special dictionary for the topics XML.  Remember the new xml format!
    }
    
    //TODO:  After your fetchs you should be able to give only the subset the other classes want, rather then the whol thing.  This class should do the hard work of making all of the data seem like one though.
    
    //MARK: - NSXMLparserDelegate
    func parserDidStartDocument(parser: NSXMLParser!) {
        self.tempFirstLevelXMLDict = Dictionary<String, NSURL>()
    }
    func parser(parser: NSXMLParser!, didStartElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!, attributes attributeDict: [NSObject : AnyObject]!) {
        if elementName == "batch" {
            var date : String = attributeDict["date"] as String
            var url : NSURL = NSURL(string: attributeDict["url"] as String)!
            self.tempFirstLevelXMLDict?.updateValue(url, forKey: date)
        }
    }
    
}
