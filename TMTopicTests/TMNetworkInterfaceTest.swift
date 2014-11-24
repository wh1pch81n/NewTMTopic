//
//  TMNetworkInterfaceTest.swift
//  TMTopic
//
//  Created by Derrick Ho on 11/9/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

import UIKit
import XCTest

let kFakeNetworkDelaySeconds : UInt32 = 5
let kDummyFirstLevelXMLPath = "DummyFirstLevelXML.xml"
let kDummySecondLevelXMLPath = "DummySecondLevelXML1.xml"

//MARK: test fetching
class TMNetworkInterfaceDataRequestTest: XCTestCase {
  let bundle : NSBundle = NSBundle(forClass: TMNetworkInterfaceDataRequestTest.self)
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testNetworkRequestFailed() {
    //set up Mocks
    class TestNSURLSession : NSURLSession {
      // To mock the call for data
      private override func dataTaskWithRequest(request: NSURLRequest, completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?) -> NSURLSessionDataTask {
        let dataMock : NSData! = NSData()
        let urlResponseMock : NSURLResponse! = NSURLResponse()
        let errorMock : NSError! = NSError()
        completionHandler!((dataMock, urlResponseMock, errorMock))
        //fake delay
        println(String(format:"Begin 'network call'"))
        sleep(kFakeNetworkDelaySeconds) //sleep 5 seconds
        println(String(format:"End 'network call'"))
        return NSURLSessionDataTask()
      }
    }
    
    // plug in
    let fetchSomethingExpectation : XCTestExpectation = expectationWithDescription("fetching something")
    var fetchStatus : TMNetwork = .fetchUnknown
    
    let networkInterface : TMNetworkInterface = TMNetworkInterface()
    networkInterface.currentSession = TestNSURLSession()
    networkInterface.fetchFirstLevelXMLBatch({ (fetchResponse : TMNetwork, batches : Array<Dictionary<String, String>>?) in
      fetchStatus = fetchResponse
      fetchSomethingExpectation.fulfill()
    })
    
    //Test
    waitForExpectationsWithTimeout(NSTimeInterval(kFakeNetworkDelaySeconds),
      handler: { (error : NSError!) -> Void in
        switch fetchStatus {
        case .fetchError:
          XCTAssert(true)
        default:
          XCTFail()
        }
    })
  }
  
  func testNetworkRequestPassed() {
    class TestNSURLSessionMock : NSURLSession {
      private override func dataTaskWithRequest(request: NSURLRequest, completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?) -> NSURLSessionDataTask {
        var dataMock : NSData! = ("<array></array>") .dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false);
        completionHandler!(dataMock, NSURLResponse(), nil)
        sleep(kFakeNetworkDelaySeconds)
        return NSURLSessionDataTask()
      }
    }
    
    let fetchSomethingExpectation = expectationWithDescription("fetching something")
    var fetchStatus : TMNetwork = .fetchUnknown
    
    let networkInterface = TMNetworkInterface()
    networkInterface.currentSession = TestNSURLSessionMock()
    networkInterface.fetchFirstLevelXMLBatch({ (fetchResponse : TMNetwork, batches : Array<Dictionary<String, String>>?) -> () in
      fetchStatus = fetchResponse
      fetchSomethingExpectation.fulfill()
    })
    
    waitForExpectationsWithTimeout(NSTimeInterval(kFakeNetworkDelaySeconds),
      handler: { (error : NSError!) -> Void in
        switch fetchStatus {
        case .fetchSuccessful:
          XCTAssert(true)
        default:
          XCTFail()
        }
    })
  }
  
  func testReceivedFirstLevelXML() {
    //first level xml only contains the post date and
    var bundle = self.bundle
    class TestNSURLSessionMock : NSURLSession {
      private override func dataTaskWithRequest(request: NSURLRequest, completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?) -> NSURLSessionDataTask {
        var dataMock : NSData! = NSData.dataFrom(
          contentsOfFile: kDummyFirstLevelXMLPath,
          encoding: NSUTF8StringEncoding,
          bundle: TMNetworkInterfaceDataRequestTest().bundle,
          error: nil)
        sleep(kFakeNetworkDelaySeconds)
        completionHandler!(dataMock, NSURLResponse(), nil)
        return NSURLSessionDataTask()
      }
    }
    let fetchSomethingExpectation = expectationWithDescription("fetching dummy data from xml file")
    var fetchStatus : TMNetwork = .fetchUnknown
    
    var networkInterface = TMNetworkInterface()
    networkInterface.currentSession = TestNSURLSessionMock()
    networkInterface.fetchFirstLevelXMLBatch { (fetchResponse : TMNetwork, batches : Array<Dictionary<String, String>>?) -> () in
      fetchStatus = fetchResponse
      fetchSomethingExpectation.fulfill()
    }
    
    waitForExpectationsWithTimeout(NSTimeInterval(kFakeNetworkDelaySeconds), handler: { (error : NSError!) -> Void in
      switch fetchStatus {
      case .fetchSuccessful:
        XCTAssert(true)
        let expected = [
          ["date" : "2014-11-15",
            "url" : "youare.com/a/wonderful/programmer"],
          ["date" : "2014-10-1",
            "url" : "www.cool.com/i/love/you"],
          ["date" : "2014-09-1",
            "url" :  "http://www.awesome.com"],
          ["date" : "2014-08-1",
            "url" : "http://www.coolurl.com"]
        ]
        let actual = networkInterface.firstLevelXMLArray!
        
        for var i = 0; i < expected.count; ++i {
          var actualStr = actual[i]["date"] as String!
          var expectedStr = expected[i]["date"] as String!
          XCTAssertEqual(actualStr!, expectedStr!)
        }
      default:
        XCTFail()
      }
    })
  }
  
  func testReceivedSecondLevelXMLFromEachFirstLevelXML() {
    var bundle = self.bundle
    class TestNSURLSessionMock : NSURLSession {
      private override func dataTaskWithRequest(request: NSURLRequest, completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?) -> NSURLSessionDataTask {
        var dataMock : NSData! = NSData.dataFrom(
          contentsOfFile: kDummySecondLevelXMLPath,
          encoding: NSUTF8StringEncoding,
          bundle: TMNetworkInterfaceDataRequestTest().bundle,
          error: nil)
        sleep(kFakeNetworkDelaySeconds)
        completionHandler!(dataMock, NSURLResponse(), nil)
        return NSURLSessionDataTask()
      }
    }
    let fetchSomethingExpectation = expectationWithDescription("fetching dummy second level")
    var fetchStatus : TMNetwork = .fetchUnknown
    
    var networkInterface = TMNetworkInterface()
    networkInterface.firstLevelXMLArray = [
      ["date" : "2014-11-15",
        "url" : "youare.com/a/wonderful/programmer"],
      ["date" : "2014-10-1",
        "url" : "www.cool.com/i/love/you"]
    ]
    
    let expected = [
      "2014-11-15" : [[
        "category" : "Science",
        "intro" : "There are questions that every child asks...",
        "min" : "2",
        "max" : "3",
        "source" : "",
        "question" : "Why is the sky blue?"
        ], [
          "question" : "What would make the world a happier place?"
        ], [
          "category" : "Wisdom",
          "intro" : "A Guru is someone that offers wisdom.  A master is someone that knows a skill really well.  A mentor is someone that can offer you help based on their life experiences",
          "question" : "Tell us of a time someone taught you something"
        ]
      ],
      "2014-10-1" : [[
        "category" : "Science",
        "intro" : "There are questions that every child asks...",
        "min" : "2",
        "max" : "3",
        "source" : "",
        "question" : "Why is the sky blue?"
        ], [
          "question" : "What would make the world a happier place?"
        ], [
          "category" : "Wisdom",
          "intro" : "A Guru is someone that offers wisdom.  A master is someone that knows a skill really well.  A mentor is someone that can offer you help based on their life experiences",
          "question" : "Tell us of a time someone taught you something"
        ]
      ]
    ]
    
    networkInterface.currentSession = TestNSURLSessionMock()
    networkInterface.fetchSecondLevelXMLTopic { (fetchStatus : TMNetwork, topics : Dictionary<String, Array<Dictionary<String, String>>>?) -> Void in
      fetchSomethingExpectation.fulfill()
    }
    
    waitForExpectationsWithTimeout(NSTimeInterval(kFakeNetworkDelaySeconds * 2), handler: { (error : NSError!) -> Void in
      // test for equivalence somehow
      XCTAssert(true)
    })

  }
  
  func testReceivedSecondLevelXMLWhenOnlyOneFirstLevelXMLIsNew() {
    
  }
  
  func testReceivedNoSecondLevelXMLBecauseDeviceHasAllOfThemAlready() {
    
  }
}

//MARK: notify all listeners of data
class TMNetworkInterfaceNotificationTest: XCTestCase {
  
  override func setUp() {
    super.setUp()
    
  }
  override func tearDown() {
    
    super.tearDown()
  }
  
  func testThatDataWasSentToDelegatePassing() {
    
  }
  
  func testThatDataWasSentToDelegateFailing() {
    
  }
  
  func testThatDataWasPostedToNotificationCenterPassing() {
    
  }
  
  func testThatDataWasPostedToNotificationCenterFailing() {
    
  }
}

//TODO: move this in to its own file
extension NSData {
  class func dataFrom(contentsOfFile filename: String!, encoding: NSStringEncoding, bundle: NSBundle!, error: NSErrorPointer) -> NSData? {
    let path = bundle.pathForResource(filename, ofType: nil)
    if let content = String(
      contentsOfFile: path!,
      encoding: encoding,
      error: error)
    {
      if let _data = content.dataUsingEncoding(encoding, allowLossyConversion: false)
      {
        return _data
      }
    }
    return nil
  }
}
