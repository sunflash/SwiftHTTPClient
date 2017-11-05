//
//  SchemeModel.swift
//  HTTPClient
//
//  Created by Min Wu on 05/07/2017.
//  Copyright © 2017 Min Wu. All rights reserved.
//

import Foundation

// MARK: - Generate DB model

class SchemeDBModel {

    fileprivate static let primaryKey = "identifier"

    fileprivate static let modelClassPrefix = "Realm"

    fileprivate static var classObjectPrefix = ""

    static func generateDBModel(_ schemeInfo: SchemeInfo) -> String {

        classObjectPrefix = schemeInfo.prefix

        // Create instances

        let swiftObject = schemeInfo.swiftType.init()
        var objects = [swiftObject]
        if let objcObject = schemeInfo.objcType?.init() {objects.append(objcObject)}

        // Empyt object look up table
        realmTypeLookUpTable.removeAll()
        propertyTypeLookUpTable.removeAll()

        // Generate realm model and mapping
        var model = SchemeUtility.generateImport(moduleNames: ["Foundation", "RealmSwift"])
        model += "// MARK: - Realm Object (\(Date()))" + newLine()
        model += generateRealmModel(object: swiftObject, primaryKeys: schemeInfo.primaryKeys, types: schemeInfo.typeInfo)
        model += "// MARK: - Map to Realm (\(Date()))" + newLine()
        model += generateObjectToRealmMapping(objects: objects, primaryKeys: schemeInfo.primaryKeys, types: schemeInfo.typeInfo)
        model += newLine() + "// MARK: - Map from Realm (\(Date()))" + newLine()
        model += generateRealmToObjectMapping(objects: objects, primaryKeys: schemeInfo.primaryKeys, types: schemeInfo.typeInfo)

        return model
    }
}

// MARK: - Generate Realm Model

extension SchemeDBModel {

    fileprivate static var realmTypeLookUpTable = [String: String]()

    private static let realmTypeTemplates: [String: String] = {
        var realmTypes = [String: String]()
        realmTypes["Bool"] = "@objc dynamic var %@ = false"
        realmTypes["Int"] = "@objc dynamic var %@ = 0"
        realmTypes["Int64"] = "@objc dynamic var %@: Int64 = 0"
        realmTypes["Float"] = "@objc dynamic var %@: Float = 0.0"
        realmTypes["Double"] = "@objc dynamic var %@: Double = 0.0"
        realmTypes["String"] = "@objc dynamic var %@ = \"\""
        realmTypes["Data"] = "@objc dynamic var %@ = Data()"
        realmTypes["Date"] = "@objc dynamic var %@ = Date()"
        realmTypes["Optional<Bool>"] = "let %@ = RealmOptional<Bool>()"
        realmTypes["Optional<Int>"] = "let %@ = RealmOptional<Int>()"
        realmTypes["Optional<Int64>"] = "let %@ = RealmOptional<Int64>()"
        realmTypes["Optional<Float>"] = "let %@ = RealmOptional<Float>()"
        realmTypes["Optional<Double>"] = "let %@ = RealmOptional<Double>()"
        realmTypes["Optional<String>"] = "@objc dynamic var %@: String?"
        realmTypes["Optional<Data>"] = "@objc dynamic var %@: Data?"
        realmTypes["Optional<Date>"] = "@objc dynamic var %@: Date?"
        realmTypes["Object"] = "@objc dynamic var %@: %@?"
        realmTypes["List"] = "let %@ = List<%@>()"
        return realmTypes
    }()

    private struct RealmTypeResult {

        var isNestedType = false

        var realmType = ""

        var nestedType = ""
    }

    fileprivate static func generateRealmModel(object: Mappable,
                                               primaryKeys: [String: [String]] = [String: [String]](),
                                               types: SchemeTypeInfo) -> String {
        let modelSubclass = "Object"

        // Extract object info and values
        let objMirror = Mirror(reflecting: object)
        let objName = "\(SchemeUtility.objectTypeDescription(mirror: objMirror))"
        let objNameWithoutPrefix = removeSubStrings(objName, [classObjectPrefix])
        let modelName = modelClassPrefix + objNameWithoutPrefix
        let objValues = object.propertyValuesRaw.sorted {$0.key < $1.key}

        var contents = [String]()
        var nestedTypes = [String]()

        // Generate realm types
        for (key, value) in objValues {
            let result = generateRealmType(objectName: objName, propertyName: key, propertyValue: value, primaryKeys: primaryKeys, types: types)
            contents.append(result.realmType)
            if result.isNestedType == true {nestedTypes.append(result.nestedType)}
        }

        // Generate primary key type
        if let primaryKeyType = primaryKeys[objName]?.first, let template = realmTypeTemplates["\(primaryKeyType)"] {
            let identifier = String(format: template, primaryKey) + newLine(2)
            contents.append(identifier)
            realmTypeLookUpTable["\(modelName).\(primaryKey)"] = primaryKeyType
        }

        // Generate realm db class contents
        contents = contents.sorted()

        if primaryKeys[objName] != nil {
            contents += generatePrimaryKey()
        }
        var realmModel = SchemeUtility.embeddedInClass(modelName, contents: contents, subclass: modelSubclass)
        nestedTypes.forEach {realmModel.append($0)}
        return realmModel
    }

    private static func generateRealmType(objectName: String,
                                          propertyName: String,
                                          propertyValue: Any,
                                          primaryKeys: [String: [String]] = [String: [String]](),
                                          types: SchemeTypeInfo) -> RealmTypeResult {

        // Make inputs mutable and extract info
        var propertyName = propertyName
        var value = propertyValue
        var type = "\(Swift.type(of: value))"
        var result = RealmTypeResult()

        // If property is primary key, assign primary key name and adjust type
        if let primaryKeyPropertyName = primaryKeys[objectName]?.first, primaryKeyPropertyName == propertyName {
            propertyName = primaryKey
            if type == "Optional<Int>" {type = "Int"}
        }

        let objNameWithoutPrefix = removeSubStrings(objectName, [classObjectPrefix])
        let modelName = modelClassPrefix + objNameWithoutPrefix
        realmTypeLookUpTable["\(modelName).\(propertyName)"] = type

        // Generate object or object array if they are optional. (need real object that is not nil to do object mapping)
        if let objectType = types.swiftObjectTypes?[propertyName] {
            value = objectType.init()
        }
        if let arrayType = types.swiftObjectArrayTypes?[propertyName] {
            value = [arrayType.init()]
        }

        // Generate realm model types
        if let template = realmTypeTemplates[type] {
            // data types (Bool, Number, String, Date..)
            let propertyNameLength = propertyName.count
            let swiftLintDisableShortIdentiferName = (propertyNameLength == 2) ? " // swiftlint:disable:this identifier_name " : ""
            result.realmType = String(format: template, propertyName) + swiftLintDisableShortIdentiferName + newLine(2)
        } else if let object = value as? Mappable, let template = realmTypeTemplates["Object"] {
            // object
            result.isNestedType = true
            let rawType = removeSubStrings(type, ["Optional", "<", ">"])
            let realmType = modelClassPrefix + rawType
            result.realmType = String(format: template, propertyName, "\(realmType)") + newLine(2)
            result.nestedType = generateRealmModel(object: object, primaryKeys: primaryKeys, types: types)
        } else if let objects = value as? [Mappable], let template = realmTypeTemplates["List"] {
            // object array
            result.isNestedType = true
            let rawType = removeSubStrings(type, ["Optional", "Array", "<", ">"])
            let realmType = modelClassPrefix + rawType
            result.realmType = String(format: template, propertyName, "\(realmType)") + newLine(2)
            objects.forEach {result.nestedType += generateRealmModel(object: $0, primaryKeys: primaryKeys, types: types)}
        } else {
            // Unknow type (MARK as UNKNOWN_TYPE)
            result.realmType = "\(propertyName) : UNKNOWN_TYPE" + newLine(2)
        }
        return result
    }

    // Generate primary key definition
    private static func generatePrimaryKey() -> [String] {
        var primaryKeyDefinition = ["override static func primaryKey() -> String? {" + newLine()]
        primaryKeyDefinition.append(tab() + "return \"\(primaryKey)\"" + newLine())
        primaryKeyDefinition.append("}" + newLine())
        return primaryKeyDefinition
    }
}

// MARK: - Generate Object to Realm mapping

extension SchemeDBModel {

    fileprivate static var propertyTypeLookUpTable = [String: String]()

    fileprivate static func generateObjectToRealmMapping(objects: [Mappable],
                                                         primaryKeys: [String: [String]] = [String: [String]](),
                                                         types: SchemeTypeInfo) -> String {

        var toRealmMappingExtension = ""

        objects.forEach { object in

            toRealmMappingExtension += generateToRealmObjectContents(object: object, primaryKeys: primaryKeys, types: types)
        }

        return toRealmMappingExtension
    }

    private static func generatePrimaryKeyDefinition(_ nestedObjectType: SchemeUtility.NestedObjectType,
                                                     _ realmTypeLowerCase: String,
                                                     _ propertyName: String,
                                                     _ primaryKeys: [String: [String]],
                                                     _ lookupKey: String) -> [String]? {

        guard var primaryKeyProperties = primaryKeys[lookupKey], primaryKeyProperties.isEmpty == false else {return nil}
        let rootObject = lookupKey.split(by: ".").first ?? ""

        primaryKeyProperties = primaryKeyProperties.map {
            $0.split(by: ".").count > 1 ? $0 : "\(rootObject).\($0)"
        }

        switch nestedObjectType {
        case .nestedObject:

            let primaryKeyProperty = primaryKeyProperties.first ?? ""
            let primaryKeyPropertyType = propertyTypeLookUpTable[primaryKeyProperty] ?? ""

            let realmObjectName = "\(capitalizingFirstLetter(realmTypeLowerCase)).\(propertyName)"
            let objectRawTypeWithoutPrefix = removeSubStrings(realmTypeLookUpTable[realmObjectName] ?? "", ["Optional", "<", ">", classObjectPrefix])
            let realmPrimaryKeyType = realmTypeLookUpTable["\(modelClassPrefix)\(objectRawTypeWithoutPrefix).\(primaryKey)"] ?? ""

            let leftSideCoalescing = isOptionalNumberType(realmPrimaryKeyType) ? ".value" : ""
            let rightSideCoalescing = generateCoalescing(primaryKeyPropertyType, realmPrimaryKeyType)

            let leftSide = "\(realmTypeLowerCase).\(propertyName)?.\(primaryKey)" + leftSideCoalescing
            let rightSide = primaryKeyProperty.replacingOccurrences(of: rootObject, with: "self") + rightSideCoalescing
            return [leftSide + " = " + rightSide]

        case .nestedObjectArray:

            let arrayIteration = "\(realmTypeLowerCase).\(propertyName).forEach {"

            let compoundPrimaryKeys: [String] = primaryKeyProperties.map {

                var primaryKeyPropertyType = propertyTypeLookUpTable[$0] ?? ""
                var primaryKeyProperty = ""
                var realmNumberValueAccessor = ""

                if $0.contains(rootObject) {
                    primaryKeyProperty = $0.replacingOccurrences(of: rootObject, with: "self")
                } else {
                    primaryKeyPropertyType = realmTypeLookUpTable[$0] ?? ""
                    primaryKeyProperty  = "$0.\($0.split(by: ".").last ?? "")"
                    realmNumberValueAccessor = isOptionalNumberType(primaryKeyPropertyType) ? ".value" : ""
                }

                let nonOptionalType = removeSubStrings(primaryKeyPropertyType, ["Optional", "<", ">"])
                let coalescing = generateCoalescing(primaryKeyPropertyType, nonOptionalType)
                return primaryKeyProperty + realmNumberValueAccessor + coalescing
            }

            let leftSide = "$0.\(primaryKey)"
            let rightSide = compoundPrimaryKeys.map {"\\(\($0))"}.joined(separator: "-")
            let assignCompoundPrimaryKey = tab() + leftSide + " = " + "\"\(rightSide)\""
            return [arrayIteration, assignCompoundPrimaryKey, "}"]
        default:
            return nil
        }
    }

    fileprivate static func generateToRealmObjectContents(object: Mappable,
                                                          primaryKeys: [String: [String]] = [String: [String]](),
                                                          types: SchemeTypeInfo) -> String {

        // Extract object info and values
        let objType = "\(type(of: object))"
        let objTypeWithoutPrefix = removeSubStrings(objType, [classObjectPrefix])
        let realmType = removeSubStrings(modelClassPrefix + objTypeWithoutPrefix, ["OBJC"])
        let realmTypeLowerCase = lowerCaseFirstLetter(realmType)

        let isSwiftObject = isSwiftObjectType(object)
        let objectTypes = isSwiftObject ? types.swiftObjectTypes : types.objcObjectTypes
        let objectArrayTypes = isSwiftObject ? types.swiftObjectArrayTypes : types.objcObjectArrayTypes

        propertyTypeLookUpTable += getPropertyTypesForObject(object)

        // Generate mapping
        var contents = [String]()
        var nestedObjectContents = [String]()
        var primaryKeyDefinitions = [String]()

        let realmObjectInit = "let \(realmTypeLowerCase) = \(realmType)()"
        contents.append(realmObjectInit)

        let objValues = object.propertyValuesRaw.sorted {$0.key < $1.key}

        for (key, value) in objValues {

            var coalescing = ""
            var propertyName = key
            var propertyType = "\(type(of: value))"

            // Adjust property name for primary key
            if let primaryKeyPropertyName = primaryKeys[objType]?.first, primaryKeyPropertyName == propertyName {
                propertyName = primaryKey
                if propertyType == "Optional<Int>" || propertyType == "Optional<Int64>" {
                    coalescing = " ?? 0"
                    propertyType = removeSubStrings(propertyType, ["Optional", "<", ">"])
                }
            }

            var leftSide = "\(realmTypeLowerCase).\(propertyName)"
            var rightSide = "self.\(key)"
            let isOptionalProperty = propertyType.contains("Optional")

            // Generate object or object array mapping
            if let nestedObject = objectTypes?[propertyName]?.init() {
                // object
                if isOptionalProperty == true {coalescing = "?"}
                rightSide += coalescing + ".toRealmObject()"
                nestedObjectContents.append(generateToRealmObjectContents(object: nestedObject, primaryKeys: primaryKeys, types: types))
                if let p = generatePrimaryKeyDefinition(.nestedObject, realmTypeLowerCase, propertyName, primaryKeys, "\(objType).\(propertyName)") {
                    primaryKeyDefinitions += p
                }
            } else if let nestedObjectArrayObject = objectArrayTypes?[propertyName]?.init() {
                // object array
                if isOptionalProperty == true {coalescing = "?"}
                rightSide += coalescing + ".forEach {\(realmTypeLowerCase).\(key).append($0.toRealmObject())}"
                contents.append(rightSide)
                nestedObjectContents.append(generateToRealmObjectContents(object: nestedObjectArrayObject, primaryKeys: primaryKeys, types: types))
                if let p = generatePrimaryKeyDefinition(.nestedObjectArray, realmTypeLowerCase, propertyName, primaryKeys, "\(objType).\(propertyName)") {
                    primaryKeyDefinitions += p
                }
                continue
            } else { // data types (Bool, Number, String, Date..)
                let realmPropertyName = "\(capitalizingFirstLetter(realmTypeLowerCase)).\(propertyName)"
                let realmPropertyType = realmTypeLookUpTable[realmPropertyName] ?? ""
                leftSide += (isOptionalNumberType(realmPropertyType) == true) ? ".value" : ""
                rightSide += coalescing
            }
            // Append mapping content
            let mapping = leftSide + " = " + rightSide
            contents.append(mapping)
        }

        if primaryKeyDefinitions.isEmpty == false {
            contents.append("")
            let primaryKeyComment = "// Set primary key for nested object and object array"
            contents.append(primaryKeyComment)
        }
        contents += primaryKeyDefinitions
        contents.append("return \(realmTypeLowerCase)")

        // Gernerate realm object extension
        let documentation = generateDocumentation(realmObjType: realmType, classObjType: objType, toRealm: true, isSwiftObject: isSwiftObject)
        let toRealmMapping = SchemeUtility.embeddedInFunction("toRealmObject", returnType: realmType, contents: contents)
        let toRealmMappingContents = documentation + toRealmMapping.lines
        var toRealmMappingExtension = SchemeUtility.embeddedInExtension("\(objType)", contents: toRealmMappingContents)
        nestedObjectContents.forEach {toRealmMappingExtension.append($0)}
        return toRealmMappingExtension
    }

}

// MARK: - Generate Realm to Object mapping

extension SchemeDBModel {

    fileprivate static func generateRealmToObjectMapping(objects: [Mappable],
                                                         primaryKeys: [String: [String]] = [String: [String]](),
                                                         types: SchemeTypeInfo) -> String {
        var fromRealmMappingExtension = ""

        objects.forEach {

            fromRealmMappingExtension += generateRealmToObjectContents(object: $0, primaryKeys: primaryKeys, types: types)
        }
        return fromRealmMappingExtension
    }

    fileprivate static func generateRealmToObjectContents(object: Mappable,
                                                          primaryKeys: [String: [String]] = [String: [String]](),
                                                          types: SchemeTypeInfo) -> String {
        // Extract object info and values
        let objType = "\(type(of: object))"
        let objTypeWithoutPrefix = removeSubStrings(objType, [classObjectPrefix])
        let realmType = removeSubStrings(modelClassPrefix + objTypeWithoutPrefix, ["OBJC"])
        let objectLowerCase = lowerCaseFirstLetter(objTypeWithoutPrefix)

        let isSwiftObject = isSwiftObjectType(object)
        let objectTypes = isSwiftObject ? types.swiftObjectTypes : types.objcObjectTypes
        let objectArrayTypes = isSwiftObject ? types.swiftObjectArrayTypes : types.objcObjectArrayTypes

        // Generate mapping
        var contents = [String]()
        var nestedObjectContents = [String]()

        let realmObjectInit = "\(isSwiftObject ? "var" : "let" ) \(objectLowerCase) = \(objType)()"
        contents.append(realmObjectInit)

        let objValues = object.propertyValuesRaw.sorted {$0.key < $1.key}

        for (key, value) in objValues {

            var coalescing = ""
            let propertyName = key
            let propertyType = "\(type(of: value))"

            var realmPropertyName = propertyName
            // Adjust realm property name for primary key
            if let primaryKeyPropertyName = primaryKeys[objType]?.first, primaryKeyPropertyName == propertyName {
                realmPropertyName = primaryKey
            }
            let realmPropertyType = realmTypeLookUpTable["\(realmType).\(realmPropertyName)"] ?? ""

            let leftSide = "\(objectLowerCase).\(propertyName)"
            var rightSide = "self.\(realmPropertyName)"
            let isOptionalProperty = propertyType.contains("Optional")

            // Generate object or object array mapping
            if let nestedObject = objectTypes?[propertyName]?.init() {
                // Object
                let nestedObjectType = "\(type(of: nestedObject))"
                if isOptionalProperty == false {coalescing = " ?? \(nestedObjectType)()"}
                rightSide += "?" + ".to\(nestedObjectType)()" + coalescing
                nestedObjectContents.append(generateRealmToObjectContents(object: nestedObject, primaryKeys: primaryKeys, types: types))
            } else if let nestedObjectArrayObject = objectArrayTypes?[propertyName]?.init() {
                // Object array
                let nestedObjectArrayType = "\(type(of: nestedObjectArrayObject))"
                rightSide += ".flatMap {$0.to\(nestedObjectArrayType)()}"
                nestedObjectContents.append(generateRealmToObjectContents(object: nestedObjectArrayObject, primaryKeys: primaryKeys, types: types))
            } else { // data types (Bool, Number, String, Date..)
                rightSide += (isOptionalNumberType(realmPropertyType) == true) ? ".value" : ""
                rightSide += generateCoalescing(realmPropertyType, propertyType)
            }
            // Append mapping content
            let mapping = leftSide + " = " + rightSide
            contents.append(mapping)
        }
        contents.append("return \(objectLowerCase)")

        // Gernerate object extension
        let documentation = generateDocumentation(realmObjType: realmType, classObjType: objType, toRealm: false, isSwiftObject: isSwiftObject)
        let toObjectMapping = SchemeUtility.embeddedInFunction("to\(objType)", returnType: objType, contents: contents)
        let toObjectMappingContents = documentation + toObjectMapping.lines
        var toObjectMappingExtension = SchemeUtility.embeddedInExtension("\(realmType)", contents: toObjectMappingContents)
        nestedObjectContents.forEach {toObjectMappingExtension.append($0)}
        return toObjectMappingExtension
    }
}

// MARK: - DB model help functions

extension SchemeDBModel {

    fileprivate static func isOptionalNumberType(_ type: String) -> Bool {
        let optionalNumberTypes = ["Optional<Int>", "Optional<Int64>", "Optional<Float>", "Optional<Double>", "Optional<Bool>"]
        return optionalNumberTypes.contains(type)
    }

    fileprivate static func isSwiftObjectType(_ object: Mappable) -> Bool {
        let mirror = Mirror(reflecting: object)
        guard "\(mirror.subjectType)".contains("OBJC") == false, let style = mirror.displayStyle else {
            return false
        }
        switch style {
        case .struct:
            return true
        case .class:
            return false
        default:
            return false
        }
    }

    fileprivate static func getPropertyTypesForObject(_ object: Mappable?) -> [String: String] {
        var types = [String: String]()
        guard let obj = object else {return types}
        let mirror = Mirror(reflecting: obj)
        mirror.children.forEach { child in
            if let key = child.label {types["\(mirror.subjectType).\(key)"] = "\(type(of: child.value))"}
        }
        return types
    }

    fileprivate static func generateCoalescing(_ fromType: String, _ toType: String) -> String {

        var coalescing = ""

        // Do type match check for swift data types that is identical
        var types = ["Int", "Int64", "Float", "Double", "Bool", "String"]
        types += ["Optional<Int>", "Optional<Int64>", "Optional<Float>", "Optional<Double>", "Optional<Bool>", "Optional<String>"]
        types += ["Date", "Optional<Date>"]

        if fromType == toType && types.contains {$0 == "\(toType)"} {
            return coalescing
        }

        // Do type match check for swift data types that is compatiable (non-option and optional type)
        let matchOptionalType: (Any.Type, Any.Type, String) -> Bool = { type, optionalType, defaultValue in
            if toType == "\(type)" && fromType == "\(optionalType)" {
                coalescing = " ?? " + defaultValue
                return true
            } else if toType == "\(optionalType)" && fromType == toType {
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
            matchOptionalType(String.self, Optional<String>.self, "\"\"") == true ||
            matchOptionalType(Date.self, Optional<Date>.self, "Date()") == true {
            return coalescing
        }
        return coalescing
    }

    fileprivate static func generateDocumentation(realmObjType: String, classObjType: String, toRealm: Bool, isSwiftObject: Bool) -> [String] {

        let realmObjDescription = "`\(realmObjType)` object"
        let classObjDescription = isSwiftObject ? "`\(classObjType)` struct" : "`\(classObjType)` object"
        let fromObjDescription = toRealm ? classObjDescription : realmObjDescription
        let returnObjDescription = toRealm ? realmObjDescription : classObjDescription

        var documentation = [String]()
        documentation.append("/// Create \(returnObjDescription) from \(fromObjDescription)" + newLine())
        documentation.append("///" + newLine())
        documentation.append("/// - Returns: \(returnObjDescription)" + newLine())
        return documentation
    }
}
