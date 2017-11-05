//
//  SchemeUtility.swift
//  HTTPClient
//
//  Created by Min Wu on 05/06/2017.
//  Copyright © 2017 Min Wu. All rights reserved.
//

import Foundation

// MARK: - Convenience string function

func newLine(_ count: Int = 1) -> String {
    return String(repeating: "\n", count: count)
}

func tab(_ count: Int = 1) -> String {
    return String(repeating: "\t", count: count)
}

func removeSubStrings(_ text: String, _ remove: [String]) -> String {
    var text = text
    remove.forEach {text = text.replacingOccurrences(of: $0, with: "")}
    return text
}

func lowerCaseFirstLetter(_ string: String) -> String {
    var s = string
    let i = s.startIndex
    s.replaceSubrange(i...i, with: String(s[i]).lowercased())
    return s
}

func capitalizingFirstLetter(_ string: String) -> String {
    var s = string
    let i = s.startIndex
    s.replaceSubrange(i...i, with: String(s[i]).uppercased())
    return s
}

// MARK: - Object common help function

class SchemeUtility {

    static func objectTypeDescription(mirror: Mirror) -> String {
        return "\(mirror.subjectType)"
    }

    enum NestedObjectType {
        case nonNestedObject
        case nestedObject
        case nestedObjectArray
    }

    /// Process data in nested data structure, if object contain another object or an array of objects.
    ///
    /// - Parameters:
    ///   - type: Type of nested object we looking after.
    ///   - value: Object that we want to do processing with.
    ///   - action: A closure with action we want to preform.
    /// - Returns: Result of the nested data structure processing.
    static func processDataInNestedStructure<T>(type: T.Type, value: Any, action: (T) -> Any) -> (nestedObjectType: NestedObjectType, data: [Any]?) {

        if let nestedObject = value as? T {
            let result = action(nestedObject)
            return (.nestedObject, [result])
        }

        if let nestedObjectArray = value as? [T] {
            var results = [Any]()
            for nestedObject in nestedObjectArray {
                let result = action(nestedObject)
                results.append(result)
            }
            return (.nestedObjectArray, results)
        }
        return (.nonNestedObject, nil)
    }
}

// MARK: - Structure generation function

extension SchemeUtility {

    static func generateImport(moduleNames: [String]) -> String {
        var imports = ""
        moduleNames.forEach {imports += "import \($0)" + newLine()}
        imports += newLine()
        return imports
    }

    static func embeddedInExtension(_ extensionType: String, contents: [String]) -> String {
        var extensionBlock = newLine()
        extensionBlock += "extension \(extensionType) {" + newLine(2)
        contents.forEach {extensionBlock += tab() + $0}
        extensionBlock += "}" + newLine()
        return extensionBlock
    }

    static func embeddedInClass(_ className: String, contents: [String], subclass: String = "", protocols: [String] = [String]()) -> String {
        var classBlock = newLine()
        var conformance = [String]()
        if subclass.isEmpty == false {conformance += [subclass]}
        conformance += protocols
        let conformanceSuffix = (conformance.isEmpty == false) ? ": \(conformance.joined(separator: ", "))" : ""
        classBlock += "class \(className)\(conformanceSuffix) {" + newLine(2)
        contents.forEach {classBlock += (tab() + $0)}
        classBlock += "}" + newLine(2)
        return classBlock
    }

    static func embeddedInFunction(_ functionName: String,
                                   parameters: [String]? = nil,
                                   returnType: String? = nil,
                                   contents: [String]) -> (function: String, lines: [String]) {
        var functionBlock = ""
        var lines = [String]()

        // Function definition
        let parameterString = parameters?.joined(separator: ", ") ?? ""
        var returnTypeString = ""
        if let returnType = returnType {
            returnTypeString = " -> \(returnType)"
        }
        let functionDefinition = "func \(functionName)(\(parameterString))\(returnTypeString) {" + newLine(2)
        functionBlock += functionDefinition
        lines.append(functionDefinition)

        // Function contents
        contents.forEach {
            let line = tab() + $0 + newLine()
            functionBlock += line
            lines.append(line)
        }

        // Function close bracket
        let functionCloseBracket = "}" + newLine()
        functionBlock += functionCloseBracket
        lines.append(functionCloseBracket)
        return (functionBlock, lines)
    }
}
