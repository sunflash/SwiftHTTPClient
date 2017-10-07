//
//  SchemeGenerator.swift
//  HTTPClient
//
//  Created by Min Wu on 05/06/2017.
//  Copyright © 2017 Min Wu. All rights reserved.
//

import Foundation

/// Scheme type info for objct and object array types
public struct SchemeTypeInfo {

    /// Swift object types
    public var swiftObjectTypes: [String:Mappable.Type]?

    /// Objective-C object types
    public var objcObjectTypes: [String:Mappable.Type]?

    /// Swift object array types
    public var swiftObjectArrayTypes: [String:Mappable.Type]?

    /// Objective-C object types
    public var objcObjectArrayTypes: [String:Mappable.Type]?

    /// Init scheme type info
    public init() {}
}

/// Scheme info for generate binding and db model
public struct SchemeInfo {

    /// Swift struct type
    public var swiftType: Mappable.Type

    /// Objective-C class type
    public var objcType: Mappable.Type?

    /// Type info for nested object and object arrays
    public var typeInfo = SchemeTypeInfo()

    /// Primary keys definition for DB model
    public var primaryKeys: [String:[String]] = [String: [String]]()

    /// Prefix used type definition
    public var prefix = ""

    /// Init scheme info
    ///
    /// - Parameter swiftType: Swift struct type
    public init(swiftType: Mappable.Type) {
        self.swiftType = swiftType
    }
}

/// Scheme generator for bindings, DB model and objects
public class SchemeGenerator {

    /// Generate swift struct to objective-c binding
    ///
    /// - Parameter schemeInfo: scheme info for generate binding
    /// - Returns: Generated swift to objective-C binding
    public static func generateOBJCBindings(_ schemeInfo: SchemeInfo) -> String {
        return SchemeBinding.generateOBJCBindings(schemeInfo)
    }

    /// Generate DB model
    ///
    /// - Parameter schemeInfo: scheme info for generate db model
    /// - Returns: Generated db model
    public static func generateDBModel(_ schemeInfo: SchemeInfo) -> String {
        return SchemeDBModel.generateDBModel(schemeInfo)
    }
}
