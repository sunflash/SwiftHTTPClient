//
//  JSONResponse.swift
//  HTTPClient
//
//  Created by Min Wu on 08/06/2017.
//  Copyright © 2017 Min WU. All rights reserved.
//

import Foundation

/// Convenience methodes to process response.
public class JSONResponse {

    private let encoder: JSONEncoder = JSONEncoder()
    private let decoder: JSONDecoder = JSONDecoder()

    /// Initializes `JSONResponse`.
    public init() {}

    /// Date formatter to encode or decode date in response.
    public var dateFormatter: DateFormatter {
        get {
            if case let JSONEncoder.DateEncodingStrategy.formatted(formatter) = encoder.dateEncodingStrategy {
                return formatter
            }
            return DefaultDateFormatter.api
        } set {
            encoder.dateEncodingStrategy = .formatted(newValue)
            decoder.dateDecodingStrategy = .formatted(newValue)
        }
    }

    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Change result type

    /// Change result to new type
    ///
    /// - Note: object won't carry along to the new type if types is not compatiable.
    ///
    /// - Parameters:
    ///   - result: `HTTPResults` that need to change type
    ///   - toType: new type for result
    /// - Returns: result to the new type
    public func changeResultType<T, U>(result: HTTPResults<U>, to toType: T.Type) -> HTTPResults<T> {

        var returnResult = HTTPResults<T>()
        returnResult.isSuccess = result.isSuccess
        returnResult.responseCode = result.responseCode
        returnResult.message = result.message
        returnResult.error = result.error
        returnResult.object = result as? T
        return returnResult
    }

    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Encode object

    /// Encode object to data
    ///
    /// - Parameter object: `Mappable` object to encode
    /// - Returns: result and data for encoding
    public func encodeObjectToData<T: Mappable>(_ object: T) -> (result: HTTPResults<T>, data: Data?) {

        var data: Data?
        var result = HTTPResults<T>()

        do {
            data = try self.encoder.encode(object)
            result.isSuccess = true
        } catch {
            let errorMessage = "Encodeing \(object.objectInfo) failed."
            result.isSuccess = false
            result.message = errorMessage
            result.error = error
            logCoder(.JSONEncode, errorMessage)
        }
        return (result, data)
    }

    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Decode success response

    /// Decode success response to result
    ///
    /// - Parameters:
    ///   - response: `HTTPResponse` from backend service
    ///   - toType: to object type
    /// - Returns: Result for decoding
    public func decodeSuccessResponse<T: Mappable>(_ response: HTTPResponse,
                                                   to toType: T.Type,
                                                   validate validateResponse: Bool = false,
                                                   decodedResult: @escaping (HTTPResults<T>) -> Void) {

        GCD.userInitiated.queue.async {

            var result = HTTPResults<T>()
            result.isSuccess = true
            result.responseCode = response.statusCode

            if let body = response.body {
                do {
                    result.object = try self.decoder.decode(toType, from: body)
                } catch {
                    let urlString = response.url?.absoluteString ?? ""
                    let errorMessage = "Decoding \(toType) failed. \(urlString)"
                    logCoder(.JSONDecode, errorMessage)
                    result.error = error
                    result.message = errorMessage
                }
            }

            GCD.main.queue.async {
                decodedResult(result)
            }
        }
    }

    /// Decode success response to result with object transformation
    ///
    /// - Parameters:
    ///   - response: `HTTPResponse` from backend service
    ///   - fromType: from object type
    ///   - toType: to object type
    ///   - transform: transform block that modify the object
    /// - Returns: Result for decoding
    public func decodeSuccessResponse<T: Mappable, R>(_ response: HTTPResponse,
                                                      from fromType: T.Type,
                                                      to toType: R.Type,
                                                      transform: @escaping (T) -> R?,
                                                      decodedResult: @escaping (HTTPResults<R>) -> Void) {

        GCD.userInitiated.queue.async {

            var transformResult = HTTPResults<R>()
            transformResult.isSuccess = true
            transformResult.responseCode = response.statusCode

            if let body = response.body {
                do {
                    let result = try self.decoder.decode(fromType, from: body)
                    transformResult.object = transform(result)
                } catch {
                    let urlString = response.url?.absoluteString ?? ""
                    let errorMessage = "Decoding \(fromType) failed. \(urlString)"
                    logCoder(.JSONDecode, errorMessage)
                    transformResult.error = error
                    transformResult.message = errorMessage
                }
            }

            GCD.main.queue.async {
                decodedResult(transformResult)
            }
        }
    }

    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Decode error response

    /// Decode error response to result
    ///
    /// - Parameter response: `HTTPResponse` from backend service
    /// - Returns: Result for decoding
    public func decodeErrorResponse<T>(_ response: HTTPResponse, to toType: T.Type, errorResult: @escaping (HTTPResults<T>) -> Void) {

        GCD.userInitiated.queue.async {

            var result = HTTPResults<T>()
            result.isSuccess = false
            result.responseCode = response.statusCode
            result.error = response.error

            GCD.main.queue.async {
                errorResult(result)
            }
        }
    }
}
