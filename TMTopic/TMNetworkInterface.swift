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
  var delegate : TMNetworkInterfaceDelegate?
  var currentSession : NSURLSession = NSURLSession.sharedSession()
  var currentNotificationCenter : NSNotificationCenter = NSNotificationCenter.defaultCenter()
  //var firstLevelXMLData : NSData?
  var firstLevelXMLDict, tempFirstLevelXMLDict : Dictionary<String, NSURL>?
  var secondLevelXMLDict, tempSecondLevelXMLDict : Dictionary<String, Dictionary<String, String>>?
  var tempTopicHolder : Dictionary<String, String>?
  
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
        //self.firstLevelXMLData = data
        var xmlparser = NSXMLParser(data: data)
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
  
  func fetchSecondLevelXMLTopic(completionHandler: (TMNetwork) -> ()) {
    if let flxd = firstLevelXMLDict {
      for (key,url) in flxd {
        let urlRequest = NSURLRequest(URL: url)
        self.currentSession.dataTaskWithRequest(urlRequest, completionHandler: { (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
          if (error != nil) || (data == nil) {
            completionHandler(TMNetwork.fetchError)
            return
          }
          var xmlParser = NSXMLParser(data: data)
          xmlParser.delegate = self
          if xmlParser.parse() == false {
            self.secondLevelXMLDict?.removeValueForKey(key)
            completionHandler(TMNetwork.processError)
            return;
          }
          self.secondLevelXMLDict?.updateValue(tempTopicHolder, forKey: key)
          completionHandler(TMNetwork.fetchSuccessful)
        }).resume()
      }
      completionHandler(TMNetwork.fetchSuccessful)
    } else {
      completionHandler(TMNetwork.fetchUnknown)
    }
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
    } else if elementName == "topic" {
      tempTopicHolder?.removeAll(keepCapacity: true)
      if let category = attributeDict["category"] as? String {
        tempTopicHolder?.updateValue(category, forKey: "category")
      }
      if let intro = attributeDict["intro"] as? String {
        tempTopicHolder?.updateValue(intro, forKey: "intro")
      }
      if let min = attributeDict["min"] as? String {
        tempTopicHolder?.updateValue(min, forKey: "min")
      }
      if let max = attributeDict["max"] as? String {
        tempTopicHolder?.updateValue(max, forKey: "max")
      }
      if let source = attributeDict["source"] as? String {
        tempTopicHolder?.updateValue(source, forKey: "source")
      }
    }
  }
  func parser(parser: NSXMLParser!, foundCharacters string: String!) {
    tempTopicHolder?.updateValue(string, forKey: "question")
  }
  func parser(parser: NSXMLParser!, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
    tempSecondLevelXMLDict
  }
}

protocol TMNetworkInterfaceDelegate {
  
}
