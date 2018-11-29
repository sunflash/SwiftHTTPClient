//
//  Mappable.swift
//  Mappable
//
//  Created by Min Wu on 22/05/2017.
//  Copyright © 2017 Min Wu. All rights reserved.
//

import Foundation

// MARK: - Mappable Protocol

/// Mappable protocol that provides extra functionality to mapped object.
public protocol Mappable: Codable {

    /// `Mappable` object's property value.
    var propertyValues: [String: Any] {get}

    /// Default requirement as part of the `Mappable` protocol, it's necessary when expose `Mappable` object through SDK framework.
    init()
}

// MARK: - Mappable Property Raw Data

extension Mappable {

    /// `Mappable` object property names that is not included computed property.
    public var propertyNamesRaw: [String] {
        return Mirror(reflecting: self).children.compactMap {$0.label}
    }

    /// `Mappable` property name value pair that is not included computed property.
    public var propertyValuesRaw: [String: Any] {

        var values = [String: Any]()
        let properties = Mirror(reflecting: self).children

        for property in properties {
            guard let propertyName = property.label else {continue}
            values[propertyName] = property.value
        }
        return values
    }

    /// `Mappable` super class property name value pair that is not included computed property.
    /// - Note: Only work with class and not sturct.
    public var superClassPropertyValuesRaw: [String: Any] {

        var values = [String: Any]()

        guard let superClassMirror = Mirror(reflecting: self).superclassMirror else {
            return values
        }
        let properties = superClassMirror.children

        for property in properties {
            guard let propertyName = property.label else {continue}
            values[propertyName] = property.value
        }
        return values
    }

    /// `Mappable` property name value pair with `Optional` value unwrapped, doesn't included computed property.
    public var propertyUnwrappedDataRaw: [String: Any] {
        return unwrapPropertyValues(propertyValuesRaw, true)
    }

    /// `Mappable` property value without computed property in description,
    /// can either print out to console for debugging, logs to file or sendt out to log collection system.
    public var objectDescriptionRaw: String {
        return generateObjectDescription(showRawDescription: true)
    }
}

// MARK: - Mappable Property Data

extension Mappable {

    /// Description of `Mappable` object, contain object name and object type info.
    public var objectInfo: String {
        let mirror = Mirror(reflecting: self)
        if let styleDescription = mirror.displayStyle?.description {
            return "\(mirror.subjectType): \(styleDescription)"
        } else {
            return "\(mirror.subjectType)"
        }
    }

    /// `Mappable` property names which is included computed property.
    public var propertyNames: [String] {
        return propertyValues.map {$0.key}
    }

    /// `Mappable` property name value pair with `Optional` value unwrapped, is included computed property.
    public var propertyUnwrappedData: [String: Any] {
        return unwrapPropertyValues(propertyValues, false)
    }

    /// `Mappable` property value with computed property as part of the description,
    /// can either print out to console for debugging, logs to file or sendt out to log collection system.
    public var objectDescription: String {
        return generateObjectDescription(showRawDescription: false)
    }
}

// MARK: - Mappable Property Methods

extension Mappable {

    /// Subscript to access `Mappable` object's property value.
    ///
    /// - Parameter key: name of the property
    public subscript (key: String) -> Any? {
        return propertyValues[key] ?? propertyValuesRaw[key]
    }

    /// Create a new property values dictionary with some property values filter out.
    ///
    /// - Parameters: 
    ///     - propertyToAdjust: Sepecifiy property need adjustment.
    ///     - property: Array of property names that should be filter out.
    /// - Returns: New property values dictionary with some property values filter out.
    private func excludePropertyValues(propertyNeedAdjust: [String: Any], excluded property: [String]) -> [String: Any] {
        var values = [String: Any]()
        propertyNeedAdjust.filter {property.contains($0.key) == false}.forEach {values[$0.key] = $0.value}
        return values
    }

    /// Adjust property values presentation for 'Mappable' object.
    /// - Note: For example, we want to hide some private, fileprivate, or raw properties values from json, and added some computed property values to the representation.
    /// In this way, we can shape what data we want consumer to see with `propertyValues`.
    /// - Parameters:
    ///   - propertyToAdjust: Sepecifiy property need adjustment, default to `propertyValuesRaw` if unspecified.
    ///   - property: Property values that we want to remove from presentation, for example private, fileprivate, or raw properties values from json.
    ///   - propertyInfo: Property values that we want to added to presentation, 
    /// that should include computed property values which is not part of the raw `Mappable` object.
    /// - Returns: A new dictionary with some raw property values removed and some computed property values added to the presentation.
    public func adjustPropertyValues(_ propertyToAdjust: [String: Any] = [String: Any](),
                                     excluded property: [String] = [""],
                                     additional propertyInfo: [String: Any] = [String: Any]()) -> [String: Any] {
        let propertyNeedAdjust = propertyToAdjust.isEmpty ? propertyValuesRaw : propertyToAdjust
        var values = excludePropertyValues(propertyNeedAdjust: propertyNeedAdjust, excluded: property)
        values += propertyInfo
        return values
    }
}

// MARK: - Mappable Nested Object

extension Mappable {

    /// Process data in nested data structure, if object contain another object or an array of objects.
    ///
    /// - Parameters:
    ///   - type: Type of nested object we looking after.
    ///   - value: Object that we want to do processing with.
    ///   - action: A closure with action we want to preform.
    /// - Returns: Result of the nested data structure processing.
    fileprivate func processDataInNestedStructure<T>(type: T.Type, value: Any, action: (T) -> Any) -> (isNestedObject: Bool, data: Any?) {

        if let nestedObject = value as? T {
            let results = action(nestedObject)
            return (true, results)
        }

        if let nestedObjectArray = value as? [T] {
            var results = [Any]()
            for nestedObject in nestedObjectArray {
                let result = action(nestedObject)
                results.append(result)
            }
            return (true, results)
        }
        return (false, nil)
    }
}

// MARK: - Mappable Property JSON Representation

extension Mappable {

    /// Show raw `Mappable` object in json representation.
    ///
    /// - Parameter dateFormatter: Date formatter that convert `Date` to `String`.
    /// - Returns: Formatted JSON representation as `String`.
    public func propertyJSONRepresentation(dateFormatter: DateFormatter) -> String {
        return generateObjectJsonRepresentation(propertyUnwrappedDataRaw, dateFormatter)
    }

    /// Generate `Mappable` object's JSON representation.
    ///
    /// - Parameters:
    ///   - unwrappedPropertyValues: Unwrapped `Mappable` property values.
    ///   - dateFormatter: Date formatter that convert `Date` to `String`.
    /// - Returns: Formatted JSON representation as `String`.
    private func generateObjectJsonRepresentation(_ unwrappedPropertyValues: [String: Any], _ dateFormatter: DateFormatter) -> String {

        let errorMessage = "Can't generate \(objectInfo) json representation."

        do {
            let jsonObject = formatDateToString(unwrappedPropertyValues, dateFormatter)
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8) ?? errorMessage
        } catch {
            logCoder(.JSONDecode, errorMessage)
            return errorMessage
        }
    }

    /// Format date to string
    ///
    /// - Parameters:
    ///   - dictionary: Unwrapped `Mappable` property values.
    ///   - dateFormatter: Date formatter that convert `Date` to `String`.
    /// - Returns: Formatted property values with `Date` converts to `String`
    private func formatDateToString(_ dictionary: [String: Any], _ dateFormatter: DateFormatter) -> [String: Any] {

        var results = [String: Any]()

        for (key, value) in dictionary {

            let type = Mirror(reflecting: value).subjectType

            let isDate = (type == Date.self) || (type == Optional<Date>.self)
            if isDate == true, let date = value as? Date {
                let dateString = dateFormatter.string(from: date)
                results[key] = dateString as Any
                continue
            }

            let result = processDataInNestedStructure(type: [String: Any].self, value: value) { nestedDictionary in
                formatDateToString(nestedDictionary, dateFormatter)
            }
            if result.isNestedObject == true {
                results[key] = result.data
                continue
            }

            results[key] = value
        }
        return results
    }
}

// MARK: - Mappable Description Methods

extension Mappable {

    /// Generate `Mappable` object to description.
    ///
    /// - Parameter showRawDescription: Flag whether what values to show, `propertyValuesRaw` or `propertyValues`
    /// - Returns: Description of property values.
    fileprivate func generateObjectDescription(showRawDescription: Bool) -> String {

        let values = (showRawDescription == true) ? propertyValuesRaw : propertyValues
        let sortedValues = values.sorted(by: {$0.key < $1.key})
        let propertyInfo = sortedValues.reduce("") {$0 + "\n\($1.key) = \(unwrappedDescription($1.value, showRawDescription))"}

        var descriptionString = separatorWithNewLine()
        descriptionString += objectInfo
        if showRawDescription == true {
            descriptionString += "\n" + "RAW"
        }
        descriptionString += separatorWithNewLine()
        descriptionString += propertyInfo
        descriptionString += separatorWithNewLine("=")
        return descriptionString
    }

    /// Get property description with optional values unwrapped.
    ///
    /// - Parameters:
    ///   - value: Value of the property, could be a nested `Mappable` object or `Mappable` object array.
    ///   - useRawValue: Flag whether what values to show, `propertyValuesRaw` or `propertyValues` with nested `Mappable` object.
    /// - Returns: Property description with optional values unwrapped.
    private func unwrappedDescription(_ value: Any, _ useRawValue: Bool) -> String {

        var value = value

        let mirror = Mirror(reflecting: value)
        if let style = mirror.displayStyle, style == .optional, let newValue = mirror.children.first?.value {
            value = newValue
        }

        let result = processDataInNestedStructure(type: Mappable.self, value: value) { mappable in
            let nestedValues = (useRawValue == true) ? mappable.propertyValuesRaw : mappable.propertyValues
            let sortedValues = nestedValues.sorted(by: {$0.key < $1.key})
            let nestedUnwrapDescriptions = sortedValues.map {"\($0.key) = \(unwrappedDescription($0.value, useRawValue))"}
            let nestedObjectDescription = nestedUnwrapDescriptions.joined(separator: ", ")
            return "{ \(nestedObjectDescription) }"
        }

        if result.isNestedObject == true {
            if let description = result.data as? String {
                return description
            } else if let descriptions = result.data as? [String] {
                return "[ \(descriptions.joined(separator: ",\n\t\t")) ]"
            }
        }

        return String(describing: value)
    }
}

// MARK: - Mappabel Unwrap Values Methods

extension Mappable {

    /// Unwrapped property values, remove `Optional` from property values.
    ///
    /// - Parameters:
    ///   - values: Property values to unwrap.
    ///   - useRawValue: Flag whether what values to unwrap, `propertyValuesRaw` or `propertyValues` with nested `Mappable` object.
    /// - Returns: Unwrapped property values.
    fileprivate func unwrapPropertyValues(_ values: [String: Any], _ useRawValue: Bool) -> [String: Any] {
        var unwrappedValues = [String: Any]()
        for (key, value) in values {
            guard let validValue = unwrapPropertyValue(value, useRawValue) else {continue}
            unwrappedValues[key] = validValue
        }
        return unwrappedValues
    }

    /// Unwrapped property value, remove `Optional` from property value.
    ///
    /// - Parameters:
    ///   - value: Property value to unwrap.
    ///   - useRawValue: Flag whether what values to unwrap, `propertyValuesRaw` or `propertyValues` with nested `Mappable` object.
    /// - Returns: Unwrapped property value.
    private func unwrapPropertyValue(_ value: Any, _ useRawValue: Bool) -> Any? {

        var value = value

        let mirror = Mirror(reflecting: value)
        if let style = mirror.displayStyle, style == .optional {
            if let newValue = mirror.children.first?.value {
                value = newValue
            } else {
                return nil
            }
        }

        let result = processDataInNestedStructure(type: Mappable.self, value: value) { mappable in
            let values = (useRawValue == true) ? mappable.propertyValuesRaw : mappable.propertyValues
            let nestedValues = unwrapPropertyValues(values, useRawValue)
            return nestedValues
        }
        if result.isNestedObject == true {return result.data}

        return value
    }
}

// MARK: - Mirror Types Extension

extension Mirror.DisplayStyle {

    /// Show `Mirror.DisplayStyle` as string.
    public var description: String {

        switch self {
        case .class:
            return "Class"
        case .collection:
            return "Collection"
        case .dictionary:
            return "Dictionary"
        case .enum:
            return "Enum"
        case .optional:
            return "Optional"
        case .set:
            return "Set"
        case .struct:
            return "Struct"
        case .tuple:
            return "Tuple"
        }
    }
}
