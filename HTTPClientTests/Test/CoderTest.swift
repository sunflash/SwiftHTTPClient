//
//  CoderTest.swift
//  HTTPClient
//
//  Created by Min Wu on 12/06/2017.
//  Copyright © 2017 Min Wu. All rights reserved.
//

import XCTest
import HTTPClient

class CoderTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        LogGlobalConfig.showCoderLog = true
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testCoder() {

        guard let data = readJSON(name: "profile") else {
            XCTFail("Read data from json file failed.")
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DefaultDateFormatter.api)

        var profile: Profile?

        do {
            profile = try decoder.decode(Profile.self, from: data)
            print(profile?.objectDescription ?? "")
        } catch {
            print(error)
            XCTFail("Decode json data failed.")
        }

        guard let profileInfo = profile else {
            XCTFail("Profile is nil.")
            return
        }

        print(profileInfo.objectDescriptionRaw)

        XCTAssertEqual(profileInfo.address?.count, 2)

        print("Property JSON Representation: \n\n")
        print(profileInfo.propertyJSONRepresentation(dateFormatter: DefaultDateFormatter.api), "\n\n")
        printSeparatorLine()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(DefaultDateFormatter.api)
        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(profile)
            let dataString = String(data: data, encoding: .utf8)
            print("Encoded JSON Pretty Printed: \n\n")
            print(dataString ?? "", "\n\n")
            printSeparatorLine()
        } catch {
            print(error)
            XCTFail("Encode json data failed.")
        }

        XCTAssertTrue(true)
    }

    func readJSON(name: String) -> Data? {
        let testBundle = Bundle(for: type(of: self))
        guard let fileURL = testBundle.url(forResource: name, withExtension: "json"),
            let data = try? Data(contentsOf: fileURL) else {
                return nil
        }
        return data
    }
}
