//
//  ClientTest.swift
//  HTTPClient
//
//  Created by Min Wu on 13/02/2017.
//  Copyright © 2017 Min Wu. All rights reserved.
//

import XCTest
import Foundation
import HTTPClient
import Kanna
import AEXML

class ClientTest: XCTestCase {

    override func setUp() {
        super.setUp()

        HTTPClient.shared.sessionBaseURL = URL(string: "https://httpbin.org")

        HTTPClient.shared.responseCompletionHandlers["PrettyPrintResponse"] = {$0.prettyPrint(showHeader: true)}
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testGetRequest() {

        let expectation = self.expectation(description: "GetRequest")

        guard let baseURL = URL(string: "https://api.github.com") else {
            XCTFail("Create url failed.")
            return
        }

        let request = HTTPRequest(path: "repos/twbs/bootstrap")

        _ = HTTPClient.shared.request(baseURL: baseURL, request: request, success: { response in

            guard let url = response.url, let contentType = response.contentType else {return}

            XCTAssertEqual(url.absoluteString, "https://api.github.com/repos/twbs/bootstrap")
            XCTAssertEqual(response.statusCode, HTTPStatusCode.ok)
            XCTAssertEqual(contentType, HTTPContentType.JSON)

            //response.prettyPrint(showHeader: true)

            var response = response
            guard let jsonDict = response.json() as? [String: AnyObject] else {return}
            XCTAssertEqual(jsonDict["full_name"] as? String, "twbs/bootstrap")
            XCTAssertEqual(jsonDict["name"] as? String, "bootstrap")
            XCTAssertEqual(jsonDict["id"] as? Int, 2126244)
            XCTAssertEqual(jsonDict["language"] as? String, "CSS")

            expectation.fulfill()
        }, error: { response in

            XCTFail(response.statusCode.statusDescription)
            expectation.fulfill()
        })

        self.waitForResponse()
    }

    func testPostDataRequest() {

        let expectation = self.expectation(description: "PostRequest")
        let bodyText = "Hello World"

        var request = HTTPRequest(path: "post", method: .post)
        request.contentType = HTTPContentType.TEXT
        request.body = bodyText.data(using: .utf8)

        _ = HTTPClient.shared.request(request: request, success: { response in

            guard response.contentType == .JSON else {
                    XCTFail("Response is not json.")
                    return
            }

            response.jsonValue(keyPath: "data") { object in

                guard let string = object as? String else {
                    XCTFail("Object is not string.")
                    return
                }

                XCTAssertEqual(string, bodyText)
                expectation.fulfill()
            }

        }, error: { response in

            XCTFail(response.statusCode.statusDescription)
            expectation.fulfill()
        })

        self.waitForResponse()
    }

    func testHTMLRequest() {

        let expectation = self.expectation(description: "HTMLRequest")

        let request = HTTPRequest(path: "html")

        _ = HTTPClient.shared.request(request: request, success: { response in

            guard let data = response.body, let html = HTML(html: data, encoding: .utf8) else {
                XCTFail("Decode html failed.")
                return
            }

            XCTAssertEqual(html.body?.xpath("//h1").first?.text, "Herman Melville - Moby-Dick")
            expectation.fulfill()

        }, error: { response in

            XCTFail(response.statusCode.statusDescription)
            expectation.fulfill()
        })

        self.waitForResponse()
    }

    func testXMLRequest() {

        let expectation = self.expectation(description: "XMLRequest")

        guard let xmlData = readXML(name: "clothes") else {
                XCTFail("Read xml data failed.")
                return
        }

        var request = HTTPRequest(path: "post", method: .post)
        request.contentType = HTTPContentType.XML
        request.body = xmlData

        _ = HTTPClient.shared.request(request: request, success: { response in

            response.jsonValue(keyPath: "data") { object in

                guard let xmlString = object as? String,
                    let data = xmlString.data(using: .utf8),
                    let xml = try? AEXMLDocument(xml: data) else {
                    XCTFail("Decode xml failed.")
                    return
                }

                XCTAssertEqual(xml.root["product"].attributes["description"], "Cardigan Sweater")
                XCTAssertEqual(xml.root["product"]["catalog_item"]["item_number"].string, "QWZ5671")
                XCTAssertEqual(xml.root["product"]["catalog_item"].last?.attributes["gender"], "Women's")
                XCTAssertEqual(xml.root["product"]["catalog_item"].last?["price"].string, "42.50")
                XCTAssertEqual(xml.root["product"]["catalog_item"].last?["size"].all(withAttributes: ["description": "Medium"])?.first?.children[3].string, "Black")
                let womanSmallElements = xml.root["product"]["catalog_item"].last?["size"].all(withAttributes: ["description": "Small"])?.first
                XCTAssertEqual(womanSmallElements?["color_swatch"].all?[1].string, "Navy")

                expectation.fulfill()
            }

        }, error: { response in

            XCTFail(response.statusCode.statusDescription)
            expectation.fulfill()
        })

        self.waitForResponse()
    }

    func testHttpResponseCode() {

        let expectation = self.expectation(description: "HttpResponse")

        let request = HTTPRequest(path: "status/404")

        _ = HTTPClient.shared.request(request: request, retry: 3, success: { _ in

            XCTFail("Response code 404 should not success.")
            expectation.fulfill()

        }, error: { response in

            XCTAssertTrue(response.statusCode == .notFound)
            expectation.fulfill()
        })

        self.waitForResponse(120)
    }

    func testRequestCancellation() {

        let expectation = self.expectation(description: "RequestCancellation")

        guard let url = URL(string: "https://google.com") else {return}

        let request = HTTPRequest()

        let cancellationToken = HTTPClient.shared.request(baseURL: url, request: request, success: { _ in

            XCTFail("Request is not cancelled as expected.")
            expectation.fulfill()

        }, error: { _ in

            XCTFail("Request is not cancelled as expected.")
            expectation.fulfill()
        })

        GCD.main.after(delay: 5) {
            XCTAssertTrue(true)
            expectation.fulfill()
        }

        cancellationToken.cancel()

        self.waitForResponse()
    }

    func testHttpBasicAuthentication() {

        let expectation = self.expectation(description: "BasicAuthentication")

        let userName = "neo"
        let password = "Y!hAA"

        var request = HTTPRequest(path: "basic-auth/\(userName)/\(password)")
        guard request.addBasicAuthentication(userName: userName, password: password) == true else {
            XCTFail("Add basic authentication to request failed.")
            return
        }

        let successBlock: (HTTPResponse) -> Void = { response in

            guard response.statusCode == .ok else {
                XCTFail("Response is not 200")
                return
            }

            var response = response
            let object = response.json() as? [String: AnyHashable]
            let authenticated = object?["authenticated"] as? Bool ?? false
            let user = object?["user"] as? String ?? ""

            XCTAssertTrue(authenticated)
            XCTAssertEqual(user, userName)
            expectation.fulfill()
        }

        let errorBlock: (HTTPResponse) -> Void = { _ in

            XCTFail("Basic authentication request failed.")
            expectation.fulfill()
        }

        _ = HTTPClient.shared.request(request: request, success: successBlock, error: errorBlock)

        self.waitForResponse()
    }

    func testImageViewExtension() {

        let expectation = self.expectation(description: "ImageViewConvenienceMethode")

        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        guard let url = URL(string: "https://httpbin.org/image/png") else {return}
        imageView.displayImage(from: url)

        GCD.main.after(delay: 5) {
            if let image = imageView.image {
                print("!! ", image.size)
                expectation.fulfill()
            } else {
                XCTFail("Image view extension fetch image failed.")
                expectation.fulfill()
            }
        }

        self.waitForResponse()
    }

    func testQueryParameter() {

        let expectation = self.expectation(description: "QueryParameter")

        HTTPClient.shared.sessionBaseURL = URL(string: "http://faketestsite.com/test/")

        var query = [URLQueryItem]()
        query.append(URLQueryItem(name: "device", value: "iPhoneX"))
        query.append(URLQueryItem(name: "scalefactor", value: "2x"))
        query.append(URLQueryItem(name: "width", value: "1125"))
        query.append(URLQueryItem(name: "height", value: "2436"))
        query.append(URLQueryItem(name: "specialCharacter", value: "æøå"))

        guard let pathWithQuery = HTTPRequest.pathWithQuery(path: "device/get-deviceInfo", queryItems: query) else {
            XCTFail("Add url querys failed.")
            return
        }

        let expectedURL = "http://faketestsite.com/test/device/get-deviceInfo?device=iPhoneX&scalefactor=2x&width=1125&height=2436&specialCharacter=%C3%A6%C3%B8%C3%A5"

        let request = HTTPRequest(path: pathWithQuery)

        _ = HTTPClient.shared.request(request: request, success: { response in

            XCTAssertEqual(response.url?.absoluteString ?? "", expectedURL)

            expectation.fulfill()

        }, error: { response in

            XCTAssertEqual(response.url?.absoluteString ?? "", expectedURL)

            expectation.fulfill()
        })

        self.waitForResponse()
    }

    func waitForResponse(_ timeout: TimeInterval = 10) {
        waitForExpectations(timeout: timeout) { error in
            if let requestError = error {
                print(requestError)
            }
        }
    }

    func readXML(name: String) -> Data? {

        let testBundle = Bundle(for: type(of: self))
        guard let fileURL = testBundle.url(forResource: name, withExtension: "xml"),
            let data = try? Data(contentsOf: fileURL) else {
                return nil
        }
        return data
    }
}
