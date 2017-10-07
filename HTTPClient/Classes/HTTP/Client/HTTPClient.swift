//
//  Http.swift
//  HTTPClient
//
//  Created by Min Wu on 10/01/2017.
//  Copyright © 2017 Min WU. All rights reserved.
//

import Foundation
import UIKit

/// Http client for network request
public class HTTPClient: Log {

    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Network property

    private var urlSession = URLSession(configuration: .default)

    /// Share instance of http client
    public static let shared = HTTPClient()

    /// Use session configuration to set global http header, cookies, access token for session
    /// URLSessionConfiguration.HTTPAdditionalHeaders
    public var configuration: URLSessionConfiguration = .default {
        didSet {
            self.urlSession.finishTasksAndInvalidate()
            self.urlSession = URLSession(configuration: self.configuration)
        }
    }

    /// Global retry parameter for all url session request, can be override local by each request
    public var retry = 0

    /// Global base url for all url session request, can be override local by each request
    public var sessionBaseURL: URL? {
        didSet {
            ReachabilityDetection.shared.stopReachabilityMonitoring()
            var reachabilityHosts = defaultReachabilityHosts
            if let baseURLHost = sessionBaseURL?.absoluteString {
                reachabilityHosts += [baseURLHost]
            }
            startReachabilityMonitoring(hosts: reachabilityHosts)
        }
    }

    /// Response completion handles that would invoke each time an http response is recevied
    public var responseCompletionHandlers: [String:(HTTPResponse) -> Void] = [String: (HTTPResponse)->Void]()

    private let defaultReachabilityHosts = ["google.com", "apple.com"]

    /// Initializes `self` with default configuration.
    public init() {
        startReachabilityMonitoring(hosts: defaultReachabilityHosts)
    }

    private func startReachabilityMonitoring(hosts: [String]) {
        let status = ReachabilityDetection.shared.startReachabilityMonitoring(hosts: hosts)
        log(.INFO, status.description)
    }

    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Network request and response

    private func gerneateURLRequest(url: URL, request: HTTPRequest) -> URLRequest {

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue

        if let contentType = request.contentType {
            urlRequest.setValue(contentType.stringValue, forHTTPHeaderField: "Content-Type")
        }

        if let headers = request.headers {
            headers.forEach {urlRequest.setValue($0.value, forHTTPHeaderField: $0.key)}
        }

        if let body = request.body {
            urlRequest.httpBody = body
        }
        return urlRequest
    }

    private func validateResponse(request: HTTPRequest, response: URLResponse?) -> Bool {

        guard let urlResponse = response as? HTTPURLResponse else {
            return false
        }

        let isSucceedRequest = (200 ... 399 ~= urlResponse.statusCode)
        var isValidContent = true

        if let expectedResponseContentType = request.expectedResponseContentType {
            let responseContentType = HTTPContentType(mimeType: urlResponse.mimeType)
            isValidContent = (expectedResponseContentType == responseContentType)
        }

        let isValidResponse = (isSucceedRequest && isValidContent)
        return isValidResponse
    }

    private func invalidRequestResponse(url: URL?) -> HTTPResponse {
        let invalidURL = HTTPStatusCode.invalidUrl
        let emptyHeaders = [String: String]()
        return HTTPResponse(url: url, statusCode: invalidURL, headers: emptyHeaders)
    }

    private func noInternetResponse(url: URL) -> HTTPResponse {
        let noInternet = HTTPStatusCode.noInternet
        let emptyHeaders = [String: String]()
        return HTTPResponse(url: url, statusCode: noInternet, headers: emptyHeaders)
    }

    private func unknownStatusResponse(url: URL, error: Error?) -> HTTPResponse {
        let unknownStatus = HTTPStatusCode.unknownStatus
        let emptyHeaders = [String: String]()
        var unknownStatusResponse = HTTPResponse(url: url, statusCode: unknownStatus, headers: emptyHeaders)
        unknownStatusResponse.error = error
        return unknownStatusResponse
    }

    private func response(response: URLResponse, data: Data? = nil, error: Error? = nil) -> HTTPResponse {

        let urlResponse = (response as? HTTPURLResponse) ?? HTTPURLResponse()
        let statusCode = HTTPStatusCode(statusCode: urlResponse.statusCode)
        let headers = lowerCaseHeaders(urlResponse.allHeaderFields as? [String:String])
        var response = HTTPResponse(url: urlResponse.url, statusCode: statusCode, headers: headers)
        response.contentType = HTTPContentType(mimeType: urlResponse.mimeType)
        response.body = data
        response.error = error
        return response
    }

    private func lowerCaseHeaders(_ headers: [String: String]?) -> [String: String] {
        var lowerCaseHeaders = [String: String]()
        headers?.forEach {lowerCaseHeaders[$0.key.lowercased()] = $0.value}
        return lowerCaseHeaders
    }

    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Network request methods

    /// Method for sending an HTTP POST/GET Request to the remote server
    ///
    /// - Parameters:
    ///   - baseURL: Base url to send the request to, fallback to session global config "sessionBaseURL" if it's nil or unspecified.
    ///   - request: HTTPRequest object
    ///   - retry: Retry request if it's failded, fallback to session global config "retry" if it's nil or unspecified.
    ///   - success: On success this block will get called.
    ///   - error: On any error this block will get called, optional.
    /// - Returns: RequestCancellationToken object for cancel request if necessary.
    public func request(baseURL: URL? = nil,
                        request: HTTPRequest,
                        retry: Int? = nil,
                        success: @escaping (HTTPResponse) -> Void,
                        error: ((HTTPResponse) -> Void)? = nil) -> RequestCancellationToken {

        var requestCancellationToken = RequestCancellationToken()

        // If request base url is unspecified, fallback to session base url
        var requestURL: URL? = baseURL ?? self.sessionBaseURL

        // Path component should only appending once and not with retry
        let shouldAppendingPathComponent = (request.retriesCount == 0)
        if shouldAppendingPathComponent == true, request.path.isEmpty == false {
            requestURL = URL(string: request.path, relativeTo: requestURL)
        }

        guard let url = requestURL?.absoluteURL, let validURL = URLComponents(url: url, resolvingAgainstBaseURL: true)?.url else {
            error?(invalidRequestResponse(url: requestURL))
            return requestCancellationToken
        }

        // use session global config self.retry if retry is nil or unspecified
        let maxRetryCount = retry ?? self.retry

        let urlRequest = self.gerneateURLRequest(url: validURL, request: request)

        let reachability = ReachabilityDetection.shared

        if reachability.monitoringHosts.isEmpty == false && reachability.isInternetAvailable == false {
            error?(noInternetResponse(url: url))
            return requestCancellationToken
        }

        let dataTask = self.urlSession.dataTask(with: urlRequest) { data, response, requestError in

            let isValidResponse = self.validateResponse(request: request, response: response)

            // retry -------------------------------------------

            guard requestCancellationToken.isTaskCancelled == false else {return} // Stop retry, if task is cancel

            if requestError != nil && requestError?._code ==  NSURLErrorTimedOut {

                if request.retriesCount < maxRetryCount {
                    var newRequest = request
                    newRequest.retriesCount += 1
                    logAPI(.request, validURL, output: "Retry \(newRequest.retriesCount)")
                    requestCancellationToken = self.request(baseURL: url, request: newRequest, retry: maxRetryCount, success: success, error: error)
                    return
                }
            }

            // error response ----------------------------------

            guard requestCancellationToken.isTaskCancelled == false else {return} // Stop calling error handle, if task is cancel

            if requestError != nil || response == nil || isValidResponse == false {
                self.errorResponseHandler(url: url, response: response, data: data, requestError: requestError, error: error)
                self.updateIndicatorDelayOnMainQueue()
                return
            }

            // success response ----------------------------------

            guard requestCancellationToken.isTaskCancelled == false else {return} // Stop calling success handle, if task is cancel

            if let successResponse = response {
                self.successResponseHandler(response: successResponse, data: data, success: success)
                self.updateIndicatorDelayOnMainQueue()
            }
        }

        dataTask.resume()
        self.updateNetworkActivityIndicator()

        requestCancellationToken.task = dataTask
        return requestCancellationToken
    }

    /// Error response handler for request
    ///
    /// - Parameters:
    ///   - url: url for request
    ///   - response: reponse return from the request, can be nil
    ///   - requestError: request error return from the request, can be nil
    ///   - error: error completion handler, can be nil if user only want completion for success only
    private func errorResponseHandler(url: URL, response: URLResponse?, data: Data?, requestError: Error?, error: ((HTTPResponse) -> Void)?) {

        guard let errorHandler = error else {return}

        let errorCompletion: (HTTPResponse) -> Void = { errorResponse in
            GCD.main.queue.async { [weak self] in
                errorHandler(errorResponse)
                self?.invokeResponseCompletionHandlers(errorResponse)
            }
        }

        if let failedResponse = response { // Error with response

            let failedResponse = self.response(response: failedResponse, data: data, error: requestError)
            errorCompletion(failedResponse)

        } else { // Error with no response

            let unknownStatusResponse = self.unknownStatusResponse(url: url, error: requestError)
            errorCompletion(unknownStatusResponse)
        }
    }

    /// Success response handler for request
    ///
    /// - Parameters:
    ///   - response: response for success request
    ///   - success: success completion handler
    private func successResponseHandler(response: URLResponse, data: Data?, success: @escaping (HTTPResponse) -> Void) {

        let successResponse = self.response(response: response, data: data)

        GCD.main.queue.async { [weak self] in
            success(successResponse)
            self?.invokeResponseCompletionHandlers(successResponse)
        }
    }

    /// Invoke each response completion handler, if there is any completion handler registed.
    ///
    /// - Parameter response: `HTTPResponse`
    private func invokeResponseCompletionHandlers(_ response: HTTPResponse) {
        responseCompletionHandlers.forEach { _, completionHandler in
            completionHandler(response)
        }
    }

    /// Remove response completion handler with name
    ///
    /// - Parameter name: name for response completion handler
    public func removeResponseCompletionHandler(_ name: String) {
        GCD.main.queue.async { [weak self] in
            self?.responseCompletionHandlers.removeValue(forKey: name)
        }
    }

    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - UI

    private func updateIndicatorDelayOnMainQueue() {

        // Update network activity indicator on main queue with a small delay
        // aften request task is return, avoid false positiv with session outstanding task count.
        GCD.main.after(delay: 0.1) { [weak self] in
            self?.updateNetworkActivityIndicator()
        }
    }

    private func updateNetworkActivityIndicator() {
        // Note: useing "func getAllTasks(completionHandler: @escaping ([URLSessionTask]) -> Void)" for iOS 9
        self.urlSession.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
           let outstandingTasksCount = [dataTasks.count, uploadTasks.count, downloadTasks.count].reduce(0, +)
            GCD.main.queue.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = (outstandingTasksCount > 0)
            }
        }
    }
}
