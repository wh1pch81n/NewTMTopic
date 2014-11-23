//
//  TMNetworkInterfaceTest.swift
//  TMTopic
//
//  Created by Derrick Ho on 11/9/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

import UIKit
import XCTest

let kFakeNetworkDelaySeconds : UInt32 = 5;
let kDummyFirstLevelXMLPath = "DummyFirstLevelXML.xml"

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
        networkInterface.fetchFirstLevelXMLBatch({ (fetchResponse : TMNetwork) in
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
        networkInterface.fetchFirstLevelXMLBatch({ (fetchResponse : TMNetwork) -> () in
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
        networkInterface.fetchFirstLevelXMLBatch { (fetchResponse : TMNetwork) -> () in
            fetchStatus = fetchResponse
            fetchSomethingExpectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(NSTimeInterval(kFakeNetworkDelaySeconds), handler: { (error : NSError!) -> Void in
            switch fetchStatus {
            case .fetchSuccessful:
                XCTAssert(true)
                var data1 : NSData! = networkInterface.firstLevelXMLData
                var data2 : NSData! = NSData.dataFrom(contentsOfFile: kDummyFirstLevelXMLPath, encoding: NSUTF8StringEncoding, bundle: self.bundle, error: nil)
                XCTAssertEqual(data1, data2)
                let expected = [
                    "2014-11-15" : NSURL(string:"youare.com/a/wonderful/programmer"),
                    "2014-10-1" : NSURL(string:"www.cool.com/i/love/you"),
                    "2014-09-1" : NSURL(string:"http://www.awesome.com"),
                    "2014-08-1" : NSURL(string:"http://www.coolurl.com")
                ]
                let actual = networkInterface.firstLevelXMLDict!
                
                for key in expected.keys {
                    if let url : NSURL = actual[key] {
                        var actualURL : NSURL! = actual[key]
                        var expectedURL : NSURL! = expected[key]!
                        XCTAssertEqual(actualURL, expectedURL)
                        continue
                    }
                    XCTFail()
                }
            default:
                XCTFail()
            }
        })
    }

    func testReceivedSecondLevelXMLFromEachFirstLevelXML() {
    
    }
    
    func testReceivedSecondLevelXMLWhenOnlyOneFirstLevelXMLIsNew() {
        
    }
    
    func testReceivedNoSecondLevelXMLBecauseDeviceHasAllOfThemAlready() {
        
    }
//    //move this function to a data extension
//    func xmlStringContentsToData(filename: String) -> NSData? {
//        var data : NSData? = nil;
//        let bundle = NSBundle(forClass: TMNetworkInterfaceDataRequestTest.self)
//        let path = bundle.pathForResource(filename, ofType: nil)
//        var err : NSErrorPointer = nil;
//        if let content = String(
//            contentsOfFile: path!,
//            encoding: NSUTF8StringEncoding,
//            error: err) {
//                if let _data = content.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
//                    data = _data
//                    return data
//                }
//        }
//        XCTFail("Could not read file")
//        return data
//    }
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
