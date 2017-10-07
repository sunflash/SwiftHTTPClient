//
//  SchemeGeneratorTest.swift
//  HTTPClient
//
//  Created by Min Wu on 21/08/2017.
//  Copyright © 2017 Min Wu. All rights reserved.
//

import XCTest
import HTTPClient

class SchemeGeneratorTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func defineSchemeTypes() -> SchemeTypeInfo {

        var schemeTypes = SchemeTypeInfo()

        let swiftObjectArrayType: [String: Mappable.Type] = ["address": Address.self]
        let swiftObjectTypes: [String: Mappable.Type] = ["mobile": Mobile.self]

        schemeTypes.swiftObjectArrayTypes = swiftObjectArrayType
        schemeTypes.swiftObjectTypes = swiftObjectTypes

        return schemeTypes
    }

    func defineProfilePrimaryKey() -> [String: [String]] {

        var primaryKeys = [String: [String]]()

        primaryKeys["Profile"] = ["id"]
        primaryKeys["Profile.mobile"] = ["id"]
        primaryKeys["Profile.address"] = ["id", "RealmAddress.type"]
        primaryKeys["Mobile"] = ["Int"]
        primaryKeys["Address"] = ["Optional<String>"]

        return primaryKeys
    }

    func defineProfileScheme() -> SchemeInfo {
        var profileSchemeInfo = SchemeInfo(swiftType: Profile.self)
        profileSchemeInfo.typeInfo = defineSchemeTypes()
        profileSchemeInfo.primaryKeys = defineProfilePrimaryKey()
        return profileSchemeInfo
    }

    func testGeneratedRealmModel() {

        let profileScheme = defineProfileScheme()
        printSeparatorLine()
        print(SchemeGenerator.generateDBModel(profileScheme))
    }
}
