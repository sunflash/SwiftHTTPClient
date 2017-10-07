//
//  DeviceInfoTest.swift
//  HTTPClient
//
//  Created by Min Wu on 04/07/2017.
//  Copyright © 2017 Min Wu. All rights reserved.
//

import XCTest
import HTTPClient

class DeviceInfoTest: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testClientInfo() {

        let deviceInfo = DeviceInfo()

        XCTAssertTrue(deviceInfo.platform.contains("OS"))
        XCTAssertTrue(deviceInfo.osVersion.compare("8.0", options: .numeric) == .orderedDescending)
        XCTAssertTrue(deviceInfo.deviceID == UIDevice.current.identifierForVendor?.uuidString)
        XCTAssertTrue(deviceInfo.country == Locale.current.regionCode)
        XCTAssertTrue(deviceInfo.language == Locale.current.languageCode)
    }
}
