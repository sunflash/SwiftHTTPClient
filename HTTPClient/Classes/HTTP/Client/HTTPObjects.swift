//
//  Http.swift
//  HTTPClient
//
//  Created by Min Wu on 06/02/2017.
//  Copyright © 2017 Min WU. All rights reserved.
//

import Foundation

//-----------------------------------------------------------------------------------------------------------------
// MARK: - Network HTTP Struct, Enum

/// Http request method enum
public enum HTTPMethod: String {

    /// The GET method requests a representation of the specified resource.
    case get     = "GET"
    /// The POST method requests that the server accept the entity enclosed in the request as a new subordinate of the web resource identified by the URI.
    case post    = "POST"
    /// The PUT method requests that the enclosed entity be stored under the supplied URI.
    case put     = "PUT"
    /// The DELETE method deletes the specified resource.
    case delete  = "DELETE"
    /// The OPTIONS method returns the HTTP methods that the server supports for the specified URL.
    case options = "OPTIONS"
    /// The HEAD method asks for a response identical to that of a GET request, but without the response body.
    case head    = "HEAD"
    /// The PATCH method applies partial modifications to a resource.
    case patch   = "PATCH"
    /// The TRACE method echoes the received request so that a client can see what (if any) changes or additions have been made by intermediate servers.
    case trace   = "TRACE"
    /// The CONNECT method converts the request connection to a transparent TCP/IP tunne.
    case connect = "CONNECT"
}

/// Http content type enum
public enum HTTPContentType {

    /// Url encode content type
    case URLENCODED
    /// Json content type
    case JSON
    /// XML content type
    case XML
    /// HTML content type
    case HTML
    /// Text content type
    case TEXT
    /// Unknown content type
    case unknown

    // MARK: - Init and enum string value

    /// Init http content type enum
    ///
    /// - Parameter mimeType: content mime type
    public init(mimeType: String?) {

        guard let type = mimeType?.lowercased() else {
            self = .unknown
            return
        }
        let isContainType: ([String]) -> Bool = {$0.filter {type.contains($0)}.isEmpty == false}

        if isContainType(["application/x-www-form-urlencoded"]) {
            self = .URLENCODED
        } else if isContainType(["application/json"]) {
            self = .JSON
        } else if isContainType(["text/xml", "application/xml"]) {
            self = .XML
        } else if isContainType(["text/html"]) {
            self = .HTML
        } else if isContainType(["text/plain"]) {
            self = .TEXT
        } else {
            self = .unknown
        }
    }

    /// Get http content type string value
    public var stringValue: String {

        switch self {
        case .URLENCODED:
            return "application/x-www-form-urlencoded"
        case .JSON:
            return "application/json"
        case .XML:
            return "text/xml"
        case .HTML:
            return "text/html"
        case .TEXT:
            return "text/plain"
        default:
            return "unknown"
        }
    }
}

//-----------------------------------------------------------------------------------------------------------------
// MARK: - HTTPRequest

/// Http request parameters and configuration
public struct HTTPRequest {

    /// Relative URL path for equest
    public let path: String
    /// Http method for request
    public let method: HTTPMethod
    /// Http content type for request, optional
    public var contentType: HTTPContentType?
    /// Http header for request, optional
    public var headers: [String: String]?
    /// Http body for request, optional
    public var body: Data?

    /// Expected response http content type to request, use for content validation, optional.
    public var expectedResponseContentType: HTTPContentType?
    /// Use internally to keeping track of how many retries was peformed, property is readonly.
    var retriesCount = 0

    /// Init method for http request
    ///
    /// - Parameters:
    ///   - path: Relative url path for content
    ///   - method: Http method for request, default to "GET"
    public init(path: String = "", method: HTTPMethod = .get) {
        self.path = path
        self.method = method
    }

    /// Generate path with query items
    ///
    /// - Parameters:
    ///   - path: relative path
    ///   - queryItems: query items
    /// - Returns: path with query items
    public static func pathWithQuery(path: String, queryItems: [URLQueryItem]) -> String? {

        var urlComponent = URLComponents(string: path)
        urlComponent?.queryItems = queryItems
        guard let url = urlComponent?.url(relativeTo: nil) else {return nil}
        return url.absoluteString
    }
}

/// Json reponse extension to HTTPResponse
private typealias BasicAuthenticationRequest = HTTPRequest

extension BasicAuthenticationRequest {

    /// Generate basic authentication header from user name and password
    ///
    /// - Parameters:
    ///   - userName: User name for authentication
    ///   - password: Password for authentication
    /// - Returns: Basic authentication header, nil if user name or password is empty.
    public static func basicAuthenticationHeader(userName: String, password: String) -> [String: String]? {

        let userNameNoSpace = userName.trimmingCharacters(in: .whitespaces)
        let passwordNoSpace = password.trimmingCharacters(in: .whitespaces)
        if userNameNoSpace.isEmpty || passwordNoSpace.isEmpty {return nil}

        let authString = "\(userNameNoSpace):\(passwordNoSpace)"
        let authStringEncoded = authString.data(using: .utf8)?.base64EncodedString()
        guard let base64String = authStringEncoded else {return nil}

        return ["Authorization": "Basic \(base64String)"]
    }

    /// Add basic authentication header to http request.
    ///
    /// - Note: Please use URLSessionConfiguration.HTTPAdditionalHeaders for session base basic authentication.
    /// - SeeAlso: [HTTPClient.configuration](../Classes/HTTPClient.html)
    ///
    /// - Parameters:
    ///   - userName: User name for authentication
    ///   - password: Password for authentication
    /// - Returns: Whether add basic authentication to request is successed.
    mutating public func addBasicAuthentication(userName: String, password: String) -> Bool {

        guard let basicAuthHeader = HTTPRequest.basicAuthenticationHeader(userName: userName, password: password) else {
            return false
        }

        if self.headers == nil {
            self.headers = basicAuthHeader
        } else {
            let headerFieldName = "Authorization"
            self.headers?[headerFieldName] = basicAuthHeader[headerFieldName]
        }
        return true
    }
}

//-----------------------------------------------------------------------------------------------------------------
// MARK: - HTTPResponse

/// Http response data
public struct HTTPResponse {

    /// URL for response
    public let url: URL?
    /// Stauts code for response
    public let statusCode: HTTPStatusCode
    /// Content type for response
    public var contentType: HTTPContentType?
    /// Headers for response
    public let headers: [String: String]
    /// Body for response
    public var body: Data?
    /// Error for response
    public var error: Error?

    /// Convient init method for http response
    ///
    /// - Parameters:
    ///   - url: URL for response
    ///   - statusCode: Stauts code for response
    ///   - headers: Headers for response
    public init(url: URL?, statusCode: HTTPStatusCode, headers: [String: String]) {
        self.url = url
        self.statusCode = statusCode
        self.headers = headers
    }

    /// Cache deserialized json object for fast lookup.
    /// Avoid unnecessary costly json deserialize operation, if json is already deserialize once before.
    fileprivate var deserializedJsonObject: Any?
}

/// Json reponse extension to HTTPResponse
private typealias JsonResponse = HTTPResponse

extension JsonResponse {

    /// Convenience property for deserialize json from response body
    public mutating func json() -> Any? {
        if self.deserializedJsonObject != nil {
            return self.deserializedJsonObject
        }
        guard let type = self.contentType, let data = self.body, type == .JSON else {return nil}

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            deserializedJsonObject = json
            return json
        } catch {
            logCoder(.JSONDecode, "\(error)")
            return nil
        }
    }

    /// Convenience methode for async deserialize json from response body.
    /// Deserialization is occur in background thread without blocking main thread, 
    /// suite for process big json payload.
    ///
    /// - Parameter object: Dedeserialize object as array or dictionary
    public func jsonDeserializeAsync(_ object: @escaping (Any?) -> Void) {

        if self.deserializedJsonObject != nil {
            return object(self.deserializedJsonObject)
        }

        guard let type = self.contentType, let data = self.body, type == .JSON else {
            object(nil)
            return
        }

        GCD.userInteractive.queue.async {

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                GCD.main.queue.async {
                    object(json)
                }
            } catch {
                logCoder(.JSONDecode, "\(error)")
            }
        }
    }

    /// Get json value with key path, perform asynchronous value look up 
    ///
    /// - Parameters:
    ///   - keyPath: key path to json value, example "coutry,city,address"
    ///   - completion: value in json key path location, nil if not found
    public func jsonValue(keyPath: String, completion: @escaping (Any?) -> Void) {

        let getValue: (Any?, @escaping (Any?) -> Void ) -> Void = { object, completion in

            GCD.userInitiated.queue.async {

                let keys = keyPath.trimmingCharacters(in: .whitespaces).split(separator: ",")

                var value = object

                if value != nil && keys.isEmpty == false {
                    keys.forEach {value = (value as? [String: Any])?[String($0)]}
                }

                GCD.main.queue.async {
                    completion(value)
                }
            }
        }

        jsonDeserializeAsync { object in
            getValue(object) { value in
                completion(value)
            }
        }
    }
}
