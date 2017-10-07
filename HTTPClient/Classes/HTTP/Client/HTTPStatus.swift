//
//  HttpStatus.swift
//  HTTPClient
//
//  Created by Min Wu on 10/01/2017.
//  Copyright © 2017 Min WU. All rights reserved.
//

import Foundation

/// Http status code enum.
/// More info https://en.wikipedia.org/wiki/List_of_HTTP_status_codes

public enum HTTPStatusCode: Int {

    /// Continue
    case `continue` = 100
    /// Switching protocol
    case switchingProtocols = 101

    /// OK
    case ok = 200 // swiftlint:disable:this identifier_name
    /// Created
    case created = 201
    /// Accepted
    case accepted = 202
    /// Non authoritative information
    case nonAuthoritativeInformation = 203
    /// No content
    case noContent = 204
    /// Reset content
    case resetContent = 205
    /// Partial content
    case partialContent = 206

    /// Multiple choices
    case multipleChoices = 300
    /// Move permanently
    case movedPermanently = 301
    /// Found
    case found = 302
    /// See other
    case seeOther = 303
    /// Not modified
    case notModified = 304
    /// Use proxy
    case useProxy = 305
    /// Unused
    case unused = 306
    /// Temporary redirect
    case temporaryRedirect = 307

    /// Bad request
    case badRequest = 400
    /// Uanauthorized
    case unauthorized = 401
    /// Payment required
    case paymentRequired = 402
    /// Forbidden
    case forbidden = 403
    /// Resource not found
    case notFound = 404
    /// Method not allowed
    case methodNotAllowed = 405
    /// Not acceptable
    case notAcceptable = 406
    /// Proxy authentication required
    case proxyAuthenticationRequired = 407
    /// Request time out
    case requestTimeout = 408
    /// Conflict
    case conflict = 409
    /// Gone
    case gone = 410
    /// Length required
    case lengthRequired = 411
    /// Precondition failed
    case preconditionFailed = 412
    /// Payload Too Large
    case payloadTooLarge = 413
    /// Payload uri too long
    case requestUriTooLong = 414
    /// Unsupported media type
    case unsupportedMediaType = 415
    /// Requested range not satisfiable
    case requestedRangeNotSatisfiable = 416
    /// Expectation failed
    case expectationFailed = 417

    /// Internal server error
    case internalServerError = 500
    /// Not implemented
    case notImplemented = 501
    /// Bad gateway
    case badGateway = 502
    /// Service unavailable
    case serviceUnavailable = 503
    /// Gateway time out
    case gatewayTimeout = 504
    /// Http version not supported
    case httpVersionNotSupported = 505

    /// Invalid url
    case invalidUrl = -1001
    /// Could not parse response
    case couldNotParseResponce = -1002
    /// Non internet connection to host
    case noInternet = -1003
    /// Unknown status
    case unknownStatus = 0

    // MARK: - Init and enum string value

    /// Init enum with status code
    ///
    /// - Parameter statusCode: status code in integer
    public init(statusCode: Int) {
        self = HTTPStatusCode(rawValue: statusCode) ?? .unknownStatus
    }

    /// Description for status code
    public var statusDescription: String {
        // swiftlint:disable line_length
        switch self {
        case .continue:
            return "The server has received the request headers and the client should proceed to send the request body (in the case of a request for which a body needs to be sent; for example, a POST request). Sending a large request body to a server after a request has been rejected for inappropriate headers would be inefficient. To have a server check the request's headers, a client must send Expect: 100-continue as a header in its initial request and receive a 100 Continue status code in response before sending the body. The response 417 Expectation Failed indicates the request should not be continued."
        case .switchingProtocols:
            return "The requester has asked the server to switch protocols and the server has agreed to do so"
        case .ok:
            return "Standard response for successful HTTP requests. The actual response will depend on the request method used. In a GET request, the response will contain an entity corresponding to the requested resource. In a POST request, the response will contain an entity describing or containing the result of the action"
        case .created:
            return "The request has been fulfilled, resulting in the creation of a new resource"
        case .accepted:
            return "The request has been accepted for processing, but the processing has not been completed. The request might or might not be eventually acted upon, and may be disallowed when processing occurs"
        case .nonAuthoritativeInformation:
            return "The server is a transforming proxy (e.g. a Web accelerator) that received a 200 OK from its origin, but is returning a modified version of the origin's response."
        case .noContent:
            return "The server successfully processed the request and is not returning any content"
        case .resetContent:
            return "The server successfully processed the request, but is not returning any content. Unlike a 204 response, this response requires that the requester reset the document view."
        case .partialContent:
            return "The server is delivering only part of the resource (byte serving) due to a range header sent by the client. The range header is used by HTTP clients to enable resuming of interrupted downloads, or split a download into multiple simultaneous streams."
        case .multipleChoices:
            return "Indicates multiple options for the resource from which the client may choose (via agent-driven content negotiation). For example, this code could be used to present multiple video format options, to list files with different filename extensions, or to suggest word-sense disambiguation"
        case .movedPermanently:
            return "This and all future requests should be directed to the given URI"
        case .found:
            return "This is an example of industry practice contradicting the standard. The HTTP/1.0 specification (RFC 1945) required the client to perform a temporary redirect (the original describing phrase was 'Moved Temporarily'),[21] but popular browsers implemented 302 with the functionality of a 303 See Other. Therefore, HTTP/1.1 added status codes 303 and 307 to distinguish between the two behaviours.[22] However, some Web applications and frameworks use the 302 status code as if it were the 303"
        case .seeOther:
            return "The response to the request can be found under another URI using a GET method. When received in response to a POST (or PUT/DELETE), the client should presume that the server has received the data and should issue a redirect with a separate GET message"
        case .notModified:
            return "Indicates that the resource has not been modified since the version specified by the request headers If-Modified-Since or If-None-Match. In such case, there is no need to retransmit the resource since the client still has a previously-downloaded copy"
        case .useProxy:
            return "The requested resource is available only through a proxy, the address for which is provided in the response. Many HTTP clients (such as Mozilla[26] and Internet Explorer) do not correctly handle responses with this status code, primarily for security reasons"
        case .unused:
            return "No longer used. Originally meant 'Subsequent requests should use the specified proxy"
        case .temporaryRedirect:
            return "In this case, the request should be repeated with another URI; however, future requests should still use the original URI. In contrast to how 302 was historically implemented, the request method is not allowed to be changed when reissuing the original request. For example, a POST request should be repeated using another POST request"
        case .badRequest:
            return "The server cannot or will not process the request due to an apparent client error (e.g., malformed request syntax, too large size, invalid request message framing, or deceptive request routing)"
        case .unauthorized:
            return "Similar to 403 Forbidden, but specifically for use when authentication is required and has failed or has not yet been provided. The response must include a WWW-Authenticate header field containing a challenge applicable to the requested resource. See Basic access authentication and Digest access authentication. 401 semantically means 'unauthenticated', i.e. the user does not have the necessary credentials. Note: Some sites issue HTTP 401 when an IP address is banned from the website (usually the website domain) and that specific address is refused permission to access a website."
        case .paymentRequired:
            return "Reserved for future use. The original intention was that this code might be used as part of some form of digital cash or micropayment scheme, but that has not happened, and this code is not usually used. Google Developers API uses this status if a particular developer has exceeded the daily limit on requests"
        case .forbidden:
            return "The request was a valid request, but the server is refusing to respond to it. The user might be logged in but does not have the necessary permissions for the resource."
        case .notFound:
            return "The requested resource could not be found but may be available in the future. Subsequent requests by the client are permissible."
        case .methodNotAllowed:
            return "A request method is not supported for the requested resource; for example, a GET request on a form which requires data to be presented via POST, or a PUT request on a read-only resource."
        case .notAcceptable:
            return "The requested resource is capable of generating only content not acceptable according to the Accept headers sent in the request"
        case .proxyAuthenticationRequired:
            return "The client must first authenticate itself with the proxy."
        case .requestTimeout:
            return "The server timed out waiting for the request. According to HTTP specifications: 'The client did not produce a request within the time that the server was prepared to wait. The client MAY repeat the request without modifications at any later time."
        case .conflict:
            return "Indicates that the request could not be processed because of conflict in the request, such as an edit conflict between multiple simultaneous updates."
        case .gone:
            return "Indicates that the resource requested is no longer available and will not be available again. This should be used when a resource has been intentionally removed and the resource should be purged. Upon receiving a 410 status code, the client should not request the resource in the future. Clients such as search engines should remove the resource from their indices. Most use cases do not require clients and search engines to purge the resource, and a '404 Not Found' may be used instead."
        case .lengthRequired:
            return "The request did not specify the length of its content, which is required by the requested resource"
        case .preconditionFailed:
            return "The server does not meet one of the preconditions that the requester put on the request"
        case .payloadTooLarge:
            return "The request is larger than the server is willing or able to process. Previously called 'Request Entity Too Large'."
        case .requestUriTooLong:
            return "The URI provided was too long for the server to process. Often the result of too much data being encoded as a query-string of a GET request, in which case it should be converted to a POST request. Called 'Request-URI Too Long' previously."
        case .unsupportedMediaType:
            return "The request entity has a media type which the server or resource does not support. For example, the client uploads an image as image/svg+xml, but the server requires that images use a different format."
        case .requestedRangeNotSatisfiable:
            return "The client has asked for a portion of the file (byte serving), but the server cannot supply that portion. For example, if the client asked for a part of the file that lies beyond the end of the file. Called 'Requested Range Not Satisfiable' previously."
        case .expectationFailed:
            return "The server cannot meet the requirements of the Expect request-header field."
        case .internalServerError:
            return "A generic error message, given when an unexpected condition was encountered and no more specific message is suitable"
        case .notImplemented:
            return "The server either does not recognize the request method, or it lacks the ability to fulfill the request. Usually this implies future availability (e.g., a new feature of a web-service API)"
        case .badGateway:
            return "The server was acting as a gateway or proxy and received an invalid response from the upstream server."
        case .serviceUnavailable:
            return "The server is currently unavailable (because it is overloaded or down for maintenance). Generally, this is a temporary state"
        case .gatewayTimeout:
            return "The server was acting as a gateway or proxy and did not receive a timely response from the upstream server."
        case .httpVersionNotSupported:
            return "The server does not support the HTTP protocol version used in the request."
        case .invalidUrl:
            return "Invalid url"
        case .noInternet:
            return "No internet connection to hosts."
        default:
            return "Unknown status code"
        }
        // swiftlint:enable line_length
    }
}
