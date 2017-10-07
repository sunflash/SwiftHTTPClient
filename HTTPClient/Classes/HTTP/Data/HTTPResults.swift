//
//  HTTPResults.swift
//  HTTPClient
//
//  Created by Min Wu on 07/06/2017.
//  Copyright © 2017 Min Wu. All rights reserved.
//

import Foundation

/// Result for transaction
public struct HTTPResults<R>: Mappable {

    /// Whether transaction is success or faild
    public var isSuccess: Bool = false

    /// Http status code for api response
    public var responseCode: HTTPStatusCode = .unknownStatus

    /// Info message from SDK or backend services
    public var message = ""

    /// Data object for transaction, could be nil
    public var object: R?

    /// Error under transaction, could be nil
    public var error: Error?

    /// Public init for HTTPResults struct
    public init() {}

    /// Creates a new instance by decoding from the given decoder.
    ///
    /// This initializer throws an error if reading from the decoder fails, or
    /// if the data read is corrupted or otherwise invalid.
    ///
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {}

    /// Encodes this value into the given encoder.
    ///
    /// If the value fails to encode anything, `encoder` will encode an empty
    /// keyed container in its place.
    ///
    /// This function throws an error if any values are invalid for the given
    /// encoder's format.
    ///
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {}

    public var propertyValues: [String : Any] {
        return propertyValuesRaw
    }
}
