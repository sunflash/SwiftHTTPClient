//
//  SchemeBinding.swift
//  HTTPClient
//
//  Created by Min Wu on 05/06/2017.
//  Copyright © 2017 Min Wu. All rights reserved.
//

import Foundation

// MARK: - Generate OBJC Bindings

class SchemeBinding {

    static func generateOBJCBindings(_ schemeInfo: SchemeInfo) -> String {

        guard let objcType = schemeInfo.objcType else {
            return "!! Objective-C objecttype was not specified."
        }

        var bindings = SchemeUtility.generateImport(moduleNames: ["Foundation"])

        // Generate binding info
        let swiftObject = schemeInfo.swiftType.init()
        let objcObject = objcType.init()

        var objToSwiftBindingInfo = SchemeBindingInfo(fromObject: objcObject, toObject: swiftObject, toSwift: true, prefix: schemeInfo.prefix)
        objToSwiftBindingInfo.typeInfo = schemeInfo.typeInfo

        var swiftToObjcBindingInfo = SchemeBindingInfo(fromObject: swiftObject, toObject: objcObject, toSwift: false, prefix: schemeInfo.prefix)
        swiftToObjcBindingInfo.typeInfo = schemeInfo.typeInfo

        // Generate bindings
        let objcToSwift = generateBinding(objToSwiftBindingInfo)
        let swiftToObjc = generateBinding(swiftToObjcBindingInfo)

        bindings += objcToSwift
        bindings += swiftToObjc

        return bindings
    }
}

// MARK: - Generate Bindings

extension SchemeBinding {

    fileprivate struct SchemeBindingInfo {

        let fromObject: Mappable

        let toObject: Mappable

        let toSwift: Bool

        let prefix: String

        var typeInfo = SchemeTypeInfo()

        init(fromObject: Mappable, toObject: Mappable, toSwift: Bool, prefix: String) {
            self.fromObject = fromObject
            self.toObject = toObject
            self.toSwift = toSwift
            self.prefix = prefix
        }
    }

    fileprivate struct SchemeBindingValue {

        let fromValue: Any

        let toValue: Any

        let toSwift: Bool

        let prefix: String

        var typeInfo = SchemeTypeInfo()

        init(fromValue: Any, toValue: Any, toSwift: Bool, prefix: String) {
            self.fromValue = fromValue
            self.toValue = toValue
            self.toSwift = toSwift
            self.prefix = prefix
        }
    }

    fileprivate struct TypeMatchResult {

        let isTypeMatch: Bool

        let coalescing: String

        let fromOptional: Bool

        let toOptional: Bool

        let nestedObjectType: SchemeUtility.NestedObjectType
    }

    fileprivate struct NestedBindingResult {

        var nestedObjectType: SchemeUtility.NestedObjectType = .nonNestedObject

        var fromObjectType = ""

        var toObjectType = ""

        var nestedBinding = ""
    }
}

extension SchemeBinding {

    // swiftlint:disable identifier_name

    fileprivate static func generateBinding(_ bindingInfo: SchemeBindingInfo) -> String {

        // Extract object type info and values
        let b = bindingInfo
        let fromObjectArrayTypes = b.toSwift ? b.typeInfo.objcObjectArrayTypes : b.typeInfo.swiftObjectArrayTypes
        let toObjectArrayTypes = b.toSwift ? b.typeInfo.swiftObjectArrayTypes : b.typeInfo.objcObjectArrayTypes
        let fromObjectTypes = b.toSwift ? b.typeInfo.objcObjectTypes : b.typeInfo.swiftObjectTypes
        let toObjectTypes = b.toSwift ? b.typeInfo.swiftObjectTypes : b.typeInfo.objcObjectTypes

        let fromObjType = SchemeUtility.objectTypeDescription(mirror: Mirror(reflecting: b.fromObject))
        let toObjType = SchemeUtility.objectTypeDescription(mirror: Mirror(reflecting: b.toObject))
        let removePrefixType = removeSubStrings(fromObjType, [bindingInfo.prefix])
        let fromObjInstance = lowerCaseFirstLetter(removePrefixType)

        let fromObjValues = b.fromObject.propertyValuesRaw.sorted {$0.key < $1.key}
        let toObjValues = b.toObject.propertyValuesRaw

        var bindingExtension = ""
        var subObjectBindingExtension = ""

        // Generate extension
        bindingExtension += "extension \(toObjType) {" + newLine(2)
        bindingExtension += generateDocumentation(fromObjType: fromObjType, toObjType: toObjType, fromObjInstance: fromObjInstance, toSwift: b.toSwift)
        bindingExtension += tab() + (b.toSwift ? "" : "convenience ") + "init(\(fromObjInstance): \(fromObjType)) {" + newLine(2)
        if b.toSwift == false {bindingExtension += tab(2) + "self.init()" + newLine()}

        // Generate type mapping
        for (key, value) in fromObjValues {

            let leftSide = "self.\(key)"
            var rightSide = "!! NO MATCH"

            // Check match property name, else continue and mark mapping with "!! NO MATCH"
            var fromValue = value
            guard var toValue = toObjValues[key] else {
                bindingExtension += (tab(2) + leftSide + " = " + rightSide + newLine())
                continue
            }

            // Do property type match check
            let match = typeMatch(key: key, fromValue: fromValue, toValue: toValue)
            guard match.isTypeMatch == true else {
                rightSide = "!! Type DOES NOT MATCH"
                bindingExtension += (tab(2) + leftSide + " = " + rightSide + newLine())
                continue
            }

            // Generate object or object array if they are optional. (need real object that is not nil to do object mapping)
            switch match.nestedObjectType {
            case .nestedObjectArray:
                fromValue = [fromObjectArrayTypes?[key]?.init()]
                toValue = [toObjectArrayTypes?[key]?.init()]
            case .nestedObject:
                fromValue = fromObjectTypes?[key]?.init() ?? fromValue
                toValue = toObjectTypes?[key]?.init() ?? toValue
            default:
                break
            }

            // Generate bindings for property and object, object array
            var schemeBindingValue = SchemeBindingValue(fromValue: fromValue, toValue: toValue, toSwift: b.toSwift, prefix: b.prefix)
            schemeBindingValue.typeInfo = bindingInfo.typeInfo

            let result = generateNestedBinding(schemeBindingValue)

            switch result.nestedObjectType {
            case .nestedObject:
                let nestedFromObjectInstance = lowerCaseFirstLetter(result.fromObjectType)
                rightSide = "\(result.toObjectType)(\(nestedFromObjectInstance): \(fromObjInstance).\(key) \(match.coalescing))"
                subObjectBindingExtension += result.nestedBinding
            case .nestedObjectArray:
                let optional = (match.fromOptional) ? "?" : ""
                let nestedFromObjectInstance = lowerCaseFirstLetter(result.fromObjectType)
                let map = "\(result.toObjectType)(\(nestedFromObjectInstance): $0)"
                rightSide = "\(fromObjInstance).\(key)" + optional + ".flatMap" + " {\(map)}" + match.coalescing
                subObjectBindingExtension += result.nestedBinding
            case .nonNestedObject:
                rightSide = "\(fromObjInstance).\(key)" + match.coalescing
            }
            bindingExtension += (tab(2) + leftSide + " = " + rightSide + newLine())
        }

        bindingExtension += tab() + "}" + newLine()
        bindingExtension += "}" + newLine(2)
        bindingExtension += subObjectBindingExtension

        return bindingExtension
    }

    fileprivate static func generateNestedBinding(_ bindingValue: SchemeBindingValue) -> NestedBindingResult {

        // Check for nested object and object array
        let fromValue = bindingValue.fromValue
        let toValue = bindingValue.toValue

        var nestedBindingResult = NestedBindingResult()

        guard let fromMappable = (fromValue as? Mappable) ?? (fromValue as? [Mappable])?.first else {
            return nestedBindingResult
        }

        guard let toMappable = (toValue as? Mappable) ?? (toValue as? [Mappable])?.first else {
            return nestedBindingResult
        }

        // Generate nested binding
        let fromObjectMirror = Mirror(reflecting: fromMappable)
        let fromObjectType = SchemeUtility.objectTypeDescription(mirror: fromObjectMirror)
        nestedBindingResult.fromObjectType = fromObjectType

        let toObjectMirror = Mirror(reflecting: toMappable)
        let toObjectType = SchemeUtility.objectTypeDescription(mirror: toObjectMirror)
        nestedBindingResult.toObjectType = toObjectType

        let result = SchemeUtility.processDataInNestedStructure(type: Mappable.self, value: fromValue) { mappable in
            var bindingInfo = SchemeBindingInfo(fromObject: mappable, toObject: toMappable, toSwift: bindingValue.toSwift, prefix: bindingValue.prefix)
            bindingInfo.typeInfo = bindingValue.typeInfo
            return generateBinding(bindingInfo)
        }

        nestedBindingResult.nestedObjectType = result.nestedObjectType

        var nestedBinding = ""
        (result.data as? [String])?.forEach {nestedBinding += $0}
        nestedBindingResult.nestedBinding = nestedBinding

        return nestedBindingResult
    }

    // MARK: - Utility Help Function

    fileprivate static func isNonNestedType(fromType: Any.Type, toType: Any.Type) -> (isTypeMatch: Bool, coalescing: String) {

        var coalescing = ""

        // Do type match check for swift data types that is identical
        var nonNestedTypes = ["Int", "Int64", "Float", "Double", "Bool", "String"]
        nonNestedTypes += ["Optional<Int>", "Optional<Int64>", "Optional<Float>", "Optional<Double>", "Optional<Bool>", "Optional<String>"]
        nonNestedTypes += ["Date", "Optional<Date>"]

        if fromType == toType && nonNestedTypes.contains {$0 == "\(toType)"} {
            return (true, coalescing)
        }

        // Do type match check for swift data types that is compatiable (non-option and optional type)
        let matchOptionalType: (Any.Type, Any.Type, String) -> Bool = { type, optionalType, defaultValue in
            if toType == type && fromType == optionalType {
                coalescing = " ?? " + defaultValue
                return true
            } else if toType == optionalType && fromType == type {
                return true
            } else {
                return false
            }
        }

        if matchOptionalType(Int.self, Optional<Int>.self, "0") == true ||
            matchOptionalType(Int64.self, Optional<Int64>.self, "0") == true ||
            matchOptionalType(Float.self, Optional<Float>.self, "0") == true ||
            matchOptionalType(Double.self, Optional<Double>.self, "0") == true ||
            matchOptionalType(Bool.self, Optional<Bool>.self, "false") == true ||
            matchOptionalType(String.self, Optional<String>.self, "\"\"") == true {
            return (true, coalescing)
        }
        return (false, coalescing)
    }

    fileprivate static func typeMatch(key: String, fromValue: Any, toValue: Any) -> TypeMatchResult {

        let fromType = type(of: fromValue)
        let toType = type(of: toValue)
        let fromOptional = "\(fromType)".contains("Optional")
        var coalescing = ""

        // Do type match check for swift data types
        let nonNestedTypeMatchResult = isNonNestedType(fromType: fromType, toType: toType)
        var toOptional = nonNestedTypeMatchResult.coalescing.isEmpty == false

        if nonNestedTypeMatchResult.isTypeMatch == true {
            return TypeMatchResult(isTypeMatch: true,
                                   coalescing: nonNestedTypeMatchResult.coalescing,
                                   fromOptional: fromOptional,
                                   toOptional: toOptional,
                                   nestedObjectType: .nonNestedObject)
        }

        // Do type match check for object
        let containArray = "\(toType)".contains("Array")
        toOptional = "\(toType)".contains("Optional")

        var fromRawType = removeSubStrings("\(fromType)", ["Optional", "<", ">"])
        var toRawType = removeSubStrings("\(toType)", ["Optional", "<", ">"])
        var fromCompareType = removeSubStrings("\(fromRawType)", ["OBJC"])
        var toCompareType = removeSubStrings("\(toRawType)", ["OBJC"])

        if containArray == false && fromCompareType == toCompareType {
            coalescing = toOptional ? "" : "?? \(fromRawType)()"
            return TypeMatchResult(isTypeMatch: true, coalescing: coalescing, fromOptional: fromOptional, toOptional: toOptional, nestedObjectType: .nestedObject)
        }

        // Do type match check for object array
        fromRawType = removeSubStrings("\(fromRawType)", ["Array"])
        toRawType = removeSubStrings("\(toRawType)", ["Array"])
        fromCompareType = removeSubStrings("\(fromCompareType)", ["Array"])
        toCompareType = removeSubStrings("\(toCompareType)", ["Array"])

        if containArray == true && fromCompareType == toCompareType {
            coalescing = toOptional ? "" : " ?? [\(toRawType)]()"
            return TypeMatchResult(isTypeMatch: true, coalescing: coalescing, fromOptional: fromOptional, toOptional: toOptional, nestedObjectType: .nestedObjectArray)
        }
        return TypeMatchResult(isTypeMatch: false, coalescing: "", fromOptional: false, toOptional: false, nestedObjectType: .nonNestedObject)
    }

    fileprivate static func generateDocumentation(fromObjType: String, toObjType: String, fromObjInstance: String, toSwift: Bool) -> String {

        let fromObjDescription = toSwift ? "objective-c compatible `\(fromObjType)` class object" : "`\(fromObjType)` struct"
        let toObjDescription = toSwift ? "`\(toObjType)` struct" : "objective-c compatible `\(toObjType)` class object"

        var documentation = tab() + "/// Init \(toObjDescription) from \(fromObjDescription)" + newLine()
        documentation += tab() + "///" + newLine()
        documentation += tab() + "/// - Parameter \(fromObjInstance): \(fromObjDescription)" + newLine()
        return documentation
    }
}
