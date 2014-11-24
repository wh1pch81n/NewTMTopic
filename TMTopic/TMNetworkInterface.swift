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
  //var delegate : TMNetworkInterfaceDelegate?
  var currentSession : NSURLSession = NSURLSession.sharedSession()
  var currentNotificationCenter : NSNotificationCenter = NSNotificationCenter.defaultCenter()
  //var firstLevelXMLData : NSData?
  var firstLevelParser : NSXMLParser?
  var firstLevelXMLArray, tempFirstLevelXMLArray : Array<Dictionary<String, String>>?
  var secondLevelParser : NSXMLParser?
  var secondLevelXMLDict, tempSecondLevelXMLDict : Dictionary<String, Array<Dictionary<String, String>>>?
  var tempTopicHolderArray : Array<Dictionary<String, String>>?
  var tempTopicHolder = Dictionary<String, String>()
  
  class var sharedInstance : TMNetworkInterface {
    struct Static {
      static let _instance : TMNetworkInterface = TMNetworkInterface()
    }
    return Static._instance
  }
  
  func fetchFirstLevelXMLBatch (fetchDone: (TMNetwork, Array<Dictionary<String, String>>?) -> Void) {
    let url : NSURL = NSURL(string: kFirstLevelXMLBatch)!
    let urlRequest = NSURLRequest(URL: url)
    self.tempFirstLevelXMLArray = Array<Dictionary<String, String>>()
    
    self.currentSession.dataTaskWithRequest(urlRequest,
      completionHandler: { (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
        if (error != nil) || (data == nil) {
          //data error
          fetchDone(TMNetwork.fetchError, nil)
          return;
        }
        var xmlparser = NSXMLParser(data: data)
        self.firstLevelParser = xmlparser
        xmlparser.delegate = self
        if xmlparser.parse() == false {
          self.firstLevelXMLArray = nil
          fetchDone(TMNetwork.processError, nil)
          return
        }
        self.firstLevelXMLArray = self.tempFirstLevelXMLArray
        fetchDone(TMNetwork.fetchSuccessful, self.firstLevelXMLArray)
    }).resume()
  }
  
  /*Fetches all data from particular from batch XML*/
  func fetchSecondLevelXMLTopic(fetchDone: (TMNetwork, Dictionary<String, Array<Dictionary<String, String>>>?) -> Void) {
    if let flxa = firstLevelXMLArray {
      self.tempSecondLevelXMLDict = Dictionary<String, Array<Dictionary<String, String>>>()
      var numBatches : Int = flxa.count
      for batch in flxa {
        self.tempTopicHolderArray = Array<Dictionary<String, String>>()
        if let url = batch["url"] {
          let urlRequest = NSURLRequest(URL: NSURL(string: url)!)
          self.currentSession.dataTaskWithRequest(urlRequest, completionHandler: { (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
            numBatches--
            if (error != nil) || (data == nil) {
              fetchDone(TMNetwork.fetchError, nil)
            } else {
              var xmlParser = NSXMLParser(data: data)
              self.secondLevelParser = xmlParser
              xmlParser.delegate = self
              if xmlParser.parse() == false {
                fetchDone(TMNetwork.processError, nil)
              } else {
                self.tempSecondLevelXMLDict?.updateValue(self.tempTopicHolderArray!, forKey: batch["date"]!)
              }
            }
            if numBatches == 0 {
              self.secondLevelXMLDict = self.tempSecondLevelXMLDict
              fetchDone(TMNetwork.fetchSuccessful, self.secondLevelXMLDict)
            }
          }).resume()
        }
      }
    } else {
      fetchDone(TMNetwork.fetchUnknown, nil)
    }
  }
  
  //TODO:  After your fetchs you should be able to give only the subset the other classes want, rather then the whol thing.  This class should do the hard work of making all of the data seem like one though.
  
  //MARK: - NSXMLparserDelegate
  func parserDidStartDocument(parser: NSXMLParser!) {
    
  }
  
  func parser(parser: NSXMLParser!, didStartElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!, attributes attributeDict: [NSObject : AnyObject]!) {
    if (parser == self.firstLevelParser) && (elementName == "batch") {
      var tempDict = Dictionary<String, String>()
      if let date = attributeDict["date"] as? String {
        tempDict.updateValue(date, forKey: "date")
      }
      if let url = attributeDict["url"] as? String {
        tempDict.updateValue(url, forKey: "url")
      }
      self.tempFirstLevelXMLArray?.append(tempDict)
    } else if (parser == self.secondLevelParser) && (elementName == "topic") {
      tempTopicHolder.removeAll(keepCapacity: true)
      if let category = attributeDict["category"] as? String {
        tempTopicHolder.updateValue(category, forKey: "category")
      }
      if let intro = attributeDict["intro"] as? String {
        tempTopicHolder.updateValue(intro, forKey: "intro")
      }
      if let min = attributeDict["min"] as? String {
        tempTopicHolder.updateValue(min, forKey: "min")
      }
      if let max = attributeDict["max"] as? String {
        tempTopicHolder.updateValue(max, forKey: "max")
      }
      if let source = attributeDict["source"] as? String {
        tempTopicHolder.updateValue(source, forKey: "source")
      }
    }
  }
  
  func parser(parser: NSXMLParser!, foundCharacters string: String!) {
    if parser == secondLevelParser {
      tempTopicHolder.updateValue(string, forKey: "question")
    }
  }
  
  func parser(parser: NSXMLParser!, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
    if parser == secondLevelParser {
      if self.tempTopicHolder.count > 0 {
        self.tempTopicHolderArray?.append(self.tempTopicHolder)
      }
    }
  }
}

//protocol TMNetworkInterfaceDelegate {
//  func firstLevelXMLParseDidFail(state : TMNetwork)
//  func firstLevelXMLParseDidSucceed(batches : Array<Dictionary<String, String>>?)
//  func secondLevelXMLParseDidFail(state : TMNetwork)
//  func secondLevelXMLParserDidSucceed(topics : Array<Dictionary<String, String>>?)
//}


//TODO: Not to self.  i feel like this data stuff is making me thing too much.  I dunno if it is because it is Swift and I hate the syntax or whatever but I dunno i feel like this is being too large of a road block.  However I think that for now you should just use what you have created thus far and move on to the next phase...which is to actually make the git hub repo specififcally for this.  Once you have done that create the main controller and try to display it.  Do not worry about persistent storage just yet...That will be for later .. get the fun stuff in and GO!