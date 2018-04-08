//
//  DeviceInfo.swift
//  HTTPClient
//
//  Created by Min Wu on 06/02/2017.
//  Copyright © 2017 Min WU. All rights reserved.
//

import Foundation
import UIKit

/// General client info
public struct DeviceInfo: Mappable {

    //-------------------------------------------------------------------------------------------
    // MARK: - System Device Info

    /// Device platform (iOS, WatchOS ...)
    public let platform = UIDevice.current.systemName

    /// Device OS Version (9.3, 10.2 ...)
    public let osVersion = UIDevice.current.systemVersion

    /// Device ID (identifierForVendor)
    public let deviceID = UIDevice.current.identifierForVendor?.description ?? ""

    //-------------------------------------------------------------------------------------------
    // MARK: - Use Defineable with System Default

    /// App version, default to "CFBundleShortVersionString"
    @objc public var appVersion: String? = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

    /// App country, default to NSLocale countryCode
    public var country: String? = Locale.current.regionCode

    /// App language, default to Locale.current.languageCode
    public var language = Locale.current.languageCode

    //-------------------------------------------------------------------------------------------
    // MARK: - DeviceInfo

    public init() {}

    public var propertyValues: [String: Any] {
        return propertyValuesRaw
    }
}
