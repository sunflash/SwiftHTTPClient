//
//  DefaultDateFormatter.swift
//  HTTPClient
//
//  Created by Min Wu on 22/05/2017.
//  Copyright © 2017 Min Wu. All rights reserved.
//

import Foundation

/// Default DateFormatter for sharing through the SDK
public class DefaultDateFormatter {

    /// Date formatter for system, use as default option for other specific formatter.
    public internal(set) static var system: DateFormatter = {
        let systemDateFormatter = DateFormatter()
        systemDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        systemDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        systemDateFormatter.timeZone = TimeZone(identifier: "UTC")
        return systemDateFormatter
    }()

    /// Shared date formatter for api date parsing, default to system date formatter.
    public static var api = system
}
