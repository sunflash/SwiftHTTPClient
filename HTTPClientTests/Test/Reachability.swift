//
//  Reachability.swift
//  HTTPClient
//
//  Created by Min Wu on 10/03/2017.
//  Copyright © 2017 Min Wu. All rights reserved.
//

import XCTest
@testable import HTTPClient

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

        let reachabilityDetection = ReachabilityDetection()
        let reachabilityStatus = reachabilityDetection.startReachabilityMonitoring(hosts: hosts)
        print("## ValidHosts :  \(reachabilityStatus.success), \(reachabilityStatus.description)")

        let validHostsExpectation = expectation(description: "ValidHosts")

        var status = [Bool]()
        let validHostCompletionHandler: (Bool) -> Void = {
            status.append($0)
        }
        reachabilityDetection.reachabilityStatusCompletionHandlers["ValidHost"] = validHostCompletionHandler

        GCD.main.after(delay: 3.5) {
            if status.contains(false) == false {
                XCTAssertTrue(reachabilityDetection.isInternetAvailable)
            } else {
                XCTFail("Valid host detection failed")
            }
            validHostsExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testNonExistHostsReachability() {

        let hosts = ["unicornant.org", "pandakinguru.com"]

        let reachabilityDetection = ReachabilityDetection()
        let reachabilityStatus = reachabilityDetection.startReachabilityMonitoring(hosts: hosts)
        print("## NonExistValidHosts :  \(reachabilityStatus.success), \(reachabilityStatus.description)")

        let nonExistHostsExpectation = expectation(description: "NonExistHostss")

        var status = [Bool]()
        let invalidHostCompletionHandler: (Bool) -> Void = {
            status.append($0)
        }
        reachabilityDetection.reachabilityStatusCompletionHandlers["InvalidHost"] = invalidHostCompletionHandler

        GCD.main.after(delay: 3.5) {
            if status.contains(false) == true {
                XCTAssertFalse(reachabilityDetection.isInternetAvailable)
            } else {
                XCTFail("Invalid host detection failed")
            }
            nonExistHostsExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }
}
