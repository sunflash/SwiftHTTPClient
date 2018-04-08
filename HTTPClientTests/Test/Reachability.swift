//
//  Reachability.swift
//  HTTPClient
//
//  Created by Min Wu on 10/03/2017.
//  Copyright © 2017 Min Wu. All rights reserved.
//

import XCTest
import HTTPClient

class Reachability: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()

        ReachabilityDetection.shared.stopReachabilityMonitoring()
        XCTAssertTrue(ReachabilityDetection.shared.monitoringHosts.isEmpty == true)
    }

    func testValidHostsReachability() {

        let hosts = ["www.google.com", "www.apple.com"]
        let reachabilityStatus = ReachabilityDetection.shared.startReachabilityMonitoring(hosts: hosts)
        print("!! ValidHosts :  \(reachabilityStatus.success), \(reachabilityStatus.description)")

        let validHostsExpectation = expectation(description: "ValidHosts")

        let validHostCompletionHandler: (Bool) -> Void = {
            print("ValidHostStatus", $0)
        }
        ReachabilityDetection.shared.reachabilityStatusCompletionHandlers["ValidHost"] = validHostCompletionHandler

        GCD.main.after(delay: 2.5) {
            XCTAssertTrue(ReachabilityDetection.shared.isInternetAvailable)
            validHostsExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testNonExistHostsReachability() {

        let nonExistHostsExpectation = expectation(description: "NonExistHosts")

        let hosts = ["unicornant.org", "pandakinguru.com"]
        let reachabilityStatus = ReachabilityDetection.shared.startReachabilityMonitoring(hosts: hosts)
        print("!! NonExistValidHosts :  \(reachabilityStatus.success), \(reachabilityStatus.description)")

        let invalidHostCompletionHandler: (Bool) -> Void = { isInternetAvailable in
            if isInternetAvailable == false {
                print("InvalidHostStatus", isInternetAvailable)
                XCTAssertTrue(true)
            }
        }
        ReachabilityDetection.shared.reachabilityStatusCompletionHandlers["InvalidHost"] = invalidHostCompletionHandler

        GCD.main.after(delay: 2.5) {
            XCTAssertFalse(ReachabilityDetection.shared.isInternetAvailable)
            nonExistHostsExpectation.fulfill()
        }
        waitForExpectations(timeout: 3)
    }
}
