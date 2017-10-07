//
//  TokenTest.swift
//  HTTPClient
//
//  Created by Min Wu on 01/09/2017.
//  Copyright © 2017 Min Wu. All rights reserved.
//

import XCTest
import HTTPClient

class TokenTest: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testJWTPayload() {

        do {
            // swiftlint:disable:next line_length
            let jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiTWluIFd1IiwicHJvZmVzc2lvbiI6IkRldmVsb3BlciIsImlzcyI6InN1bmZsYXNoIiwiaWF0IjoxNTA0OTU4NDAwLCJleHAiOjE1MDQ5NjIwMDB9.f8zeAK3Me3UBbEJi-aPp-TzfwycTnVOCbS-yn8a-st4"

            let payload = try JWTInfo.decodePayload(jwt)
            print(payload.rawPayloadData)

            XCTAssertTrue((payload.rawPayloadData["name"] as? String) ?? "" == "Min Wu")
            XCTAssertTrue((payload.rawPayloadData["profession"] as? String) ?? "" == "Developer")
            XCTAssertTrue(payload.issuer == "sunflash")

            let dateFormatter = DefaultDateFormatter.api
            XCTAssertTrue(payload.issuedAt == dateFormatter.date(from: "2017-09-09T12:00:00.000Z"))
            XCTAssertTrue(payload.expiration == dateFormatter.date(from: "2017-09-09T13:00:00.000Z"))

        } catch {

            XCTFail(error.localizedDescription)
        }
    }

    func generateTestToken(expiration: TimeInterval) -> String {
        let payload = ["exp": expiration]
        guard let payloadData = try? JSONSerialization.data(withJSONObject: payload) else {
            return ""
        }
        let payload64Encoded = JWTInfo.base64encode(payloadData)
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.\(payload64Encoded).Q0Gq3ttUbIz1ffLwbdpbb7LDqP9clASbAeY9UegZ51Y"
    }

    func testTokenExpireCheck() {

        let expectation = self.expectation(description: "TokenExpired")

        let tokenHelper = TokenHelper(tokenPersistenceKey: "BaseTokenTest")
        tokenHelper.keychainPrefix = "BaseSDKTestCase"

        // SchedulerTokenExpireCheck with test token
        tokenHelper.checkTokenExpireTimeInterval = 3
        let expiredTimeFromNow: TimeInterval = 11
        let expiration = Date().timeIntervalSince1970 + expiredTimeFromNow
        let testToken = generateTestToken(expiration: expiration)
        tokenHelper.schedulerTokenExpireCheck(testToken)

        tokenHelper.tokenExpiredHandler = {

            // Validation test with test token
            let timeToExpire = expiration - Date().timeIntervalSince1970
            printSeparatorLine()
            print("!! Expiration :", Date(timeIntervalSince1970: expiration))
            print("!! Now :", Date())
            print("!! Time to expire:", timeToExpire)
            printSeparatorLine()
            XCTAssertTrue(timeToExpire < tokenHelper.checkTokenExpireTimeInterval)

            expectation.fulfill()
        }

        let wait = expiredTimeFromNow + 2
        self.waitForResponse(wait)
    }

    func waitForResponse(_ timeout: TimeInterval = 10) {
        waitForExpectations(timeout: timeout) { error in
            if let requestError = error {
                print(requestError)
            }
        }
    }

}
