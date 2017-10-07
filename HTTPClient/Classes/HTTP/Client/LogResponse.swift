//
//  LogResponse.swift
//  HTTPClient
//
//  Created by Min Wu on 02/09/2017.
//  Copyright © 2017 Min WU. All rights reserved.
//

import Foundation

extension HTTPResponse {

    /// Add convenience methode to pretty print `HTTPResponse` data to console
    ///
    /// - Parameters:
    ///   - showHeader: Whether show header in console output, default is false
    ///   - showBody: Whether show body in console output, default is true
    public func prettyPrint(showHeader: Bool = false, showBody: Bool = true) {

        GCD.userInteractive.queue.async {

            let separator = separatorWithNewLine()
            var description = ""

            description += separator
            description += "URL: \(self.url?.absoluteString ?? "")" + newLine()
            description += "StatusCode: \(self.statusCode.rawValue)" + newLine()
            description += "ContentType: \(self.contentType?.stringValue ?? "")"
            description += separator

            if showHeader == true {
                self.headers.forEach {
                    description += $0.key + ": " + $0.value + newLine()
                }
                description += separator
            }

            if let responseError = self.error {
                description += "\(responseError)" + newLine()
                description += responseError.localizedDescription
                description += separator
            }

            guard showBody == true, let body = self.body else {
                print(description)
                return
            }

            let decodeJSON: (Data) -> String = { data in
                do { return "\(try JSONSerialization.jsonObject(with: data, options: .mutableContainers))"} catch { return "\(error)" }
            }

            let decodeString: (Data) -> String = {String(data: $0, encoding: .utf8) ?? ""}

            if let httpContentType = self.contentType {
                switch httpContentType {
                case .JSON:
                    description += decodeJSON(body)
                default:
                    description += decodeString(body)
                }
            } else {
                description += decodeString(body)
            }

            description += separator

            print(description)
        }
    }
}
