//
//  JWTInfo.swift
//  HTTPClient
//
//  Created by Min Wu on 28/08/2017.
//  Copyright © 2017 Min WU. All rights reserved.
//

import Foundation

/// Failure reasons from decoding a JWT
public enum InvalidJWT: CustomStringConvertible, Error {
    /// Decoding the JWT itself failed
    case decodeError(String)

    /// The JWT uses an unsupported algorithm
    case invalidAlgorithm

    /// The issued claim has expired
    case expiredSignature

    /// The issued claim is for the future
    case immatureSignature

    /// The claim is for the future
    case invalidIssuedAt

    /// The audience of the claim doesn't match
    case invalidAudience

    /// The issuer claim failed to verify
    case invalidIssuer

    /// Returns a readable description of the error
    public var description: String {
        switch self {
        case .decodeError(let error):
            return "Decode Error: \(error)"
        case .invalidIssuer:
            return "Invalid Issuer"
        case .expiredSignature:
            return "Expired Signature"
        case .immatureSignature:
            return "The token is not yet valid (not before claim)"
        case .invalidIssuedAt:
            return "Issued at claim (iat) is in the future"
        case .invalidAudience:
            return "Invalid Audience"
        case .invalidAlgorithm:
            return "Unsupported algorithm or incorrect key"
        }
    }
}

/// Struct for json web token payload
public struct JWTPayload {

    /// Issuer (iss) - identifies principal that issued the JWT
    public var issuer: String?

    /// Subject (sub) - identifies the subject of the JWT
    public var subject: String?

    /// Audience (aud) - The "aud" (audience) claim identifies the recipients that the JWT is intended for.
    /// Each principal intended to process the JWT MUST identify itself with a value in the audience claim.
    /// If the principal processing the claim does not identify itself with a value in the aud claim when this claim is present, then the JWT MUST be rejected.
    public var audience: String?

    /// Expiration time (exp) - The "exp" (expiration time) claim identifies the expiration time on or after which the JWT MUST NOT be accepted for processing.
    public var expiration: Date?

    /// Not before (nbf) - Similarly, the not-before time claim identifies the time on which the JWT will start to be accepted for processing.
    public var notBefore: Date?

    /// Issued at (iat) - The "iat" (issued at) claim identifies the time at which the JWT was issued.
    public var issuedAt: Date?

    /// JWT ID (jti) - case sensitive unique identifier of the token even among different issuers.
    public var uniqueID: String?

    /// Raw JWT payload data
    public var rawPayloadData: [String:Any] = [String: Any]()

    /// Default requirement as part of the `Mappable` protocol, it's necessary when expose `Mappable` object through SDK framework.
    public init() {}
}

/// JSON Web Token info
public struct JWTInfo {

    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Decode

    private static let getNumericDate: (Any?) -> Date? = {
        guard let timeInterval = $0 as? TimeInterval else {return nil}
        return Date(timeIntervalSince1970: timeInterval)
    }

    /// Decode json web token payload
    ///
    /// - Parameter jwt: json web token
    /// - Returns: decoded json web token data
    /// - Throws: In case json web token is invalid
    public static func decodePayload(_ jwt: String) throws -> JWTPayload {

        let segments = jwt.components(separatedBy: ".")

        if segments.count < 3 {
            throw InvalidJWT.decodeError("Not enough segments")
        }

        let payloadSegment = segments[1]

        guard let payloadData = base64decode(payloadSegment) else {
            throw InvalidJWT.decodeError("Payload is not correctly encoded as base64")
        }

        guard let payload = (try? JSONSerialization.jsonObject(with: payloadData, options: JSONSerialization.ReadingOptions(rawValue: 0))) as? [String:Any] else {
            throw InvalidJWT.decodeError("Invalid payload")
        }

        var payloadValues = JWTPayload()
        payloadValues.rawPayloadData = payload
        payloadValues.issuer = payload["iss"] as? String
        payloadValues.subject = payload["sub"] as? String
        payloadValues.audience = payload["aud"] as? String
        payloadValues.uniqueID = payload["jti"] as? String
        payloadValues.issuedAt = getNumericDate(payload["iat"])
        payloadValues.notBefore = getNumericDate(payload["nbf"])
        payloadValues.expiration = getNumericDate(payload["exp"])
        return payloadValues
    }

    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Utility function

    /// Base64 decode string
    ///
    /// - Parameter string: base64 string to decode
    /// - Returns: base64 decoded `Data`
    public static func base64decode(_ string: String) -> Data? {
        let rem = string.characters.count % 4

        var ending = ""
        if rem > 0 {
            let amount = 4 - rem
            ending = String(repeating: "=", count: amount)
        }

        let base64 = string.replacingOccurrences(of: "-", with: "+", options: String.CompareOptions(rawValue: 0), range: nil)
            .replacingOccurrences(of: "_", with: "/", options: String.CompareOptions(rawValue: 0), range: nil) + ending

        return Data(base64Encoded: base64, options: Data.Base64DecodingOptions(rawValue: 0))
    }

    /// Base64 encode data
    ///
    /// - Parameter data: `Data` to encode
    /// - Returns: base64 encoded `String`
    public static func base64encode(_ data: Data) -> String {
        let data = data.base64EncodedData(options: Data.Base64EncodingOptions(rawValue: 0))
        let string = String(data: data, encoding: .utf8) ?? ""
        return string
            .replacingOccurrences(of: "+", with: "-", options: String.CompareOptions(rawValue: 0), range: nil)
            .replacingOccurrences(of: "/", with: "_", options: String.CompareOptions(rawValue: 0), range: nil)
            .replacingOccurrences(of: "=", with: "", options: String.CompareOptions(rawValue: 0), range: nil)
    }
}
