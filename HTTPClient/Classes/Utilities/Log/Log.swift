//
//  Log.swift
//  Mappable
//
//  Created by Min Wu on 18/05/2017.
//  Copyright © 2017 Min Wu. All rights reserved.
//

import Foundation

//-----------------------------------------------------------------------------------------------------------------
// MARK: - Log global config

/// Log's global configurations. Use to enable and disable log's globally.
public class LogGlobalConfig {

    /// Global configuration for `Warning` log.
    public static var showWarningLog = false

    /// Global configuration for `Error` log.
    public static var showErrorLog = false

    /// Global configuration for `Debug` log.
    public static var showDebugLog = false

    /// Global configuration for `Info` log.
    public static var showInfoLog = false

    /// Global configuration for `Verbose` log.
    /// That indludes `Warning`, `Error`, `Debug`, `Info` and `Verbose` logs.
    public static var showVerboseLog = false

    /// Global configuration for `API` and api related log.
    public static var showAPILog = false

    /// Global configuration for log's under data encoding and decoding.
    public static var showCoderLog = false

    /// Global configuration for log's under database transaction.
    public static var showDBLog = false
}

//-----------------------------------------------------------------------------------------------------------------
// MARK: - General logging

/// Log's type enum.
///
/// - `WARNING`: enum case for `Warning` log.
/// - `ERROR`: enum case for `Error` log.
/// - `DEBUG`: enum case for `Debug` log.
/// - `INFO`: enum case for `Info` log.
/// - `VERBOSE`: enum case for `Verbose` log.
public enum LogType {
    /// Enum case for `Warning` log.
    case WARNING
    /// Enum case for `Error` log.
    case ERROR
    /// Enum case for `Debug` log.
    case DEBUG
    /// Enum case for `Info` log.
    case INFO
    /// Enum case for `Verbose` log.
    case VERBOSE
}

/// Log's protocol.
public protocol Log {

    /// Boolean whether to show `Warning` log.
    var showWarningLog: Bool {get}
    /// Boolean whether to show `Error` log.
    var showErrorLog: Bool {get}
    /// Boolean whether to show `Debug` log.
    var showDebugLog: Bool {get}
    /// Boolean whether to show `Info` log.
    var showInfoLog: Bool {get}
    /// Boolean whether to show `Verbose` log.
    var showVerboseLog: Bool {get}

    /// Function to log message to console.
    func log(_ type: LogType, _ message: String)
}

extension Log {

    /// Use global `Warning` log config as default.
    public var showWarningLog: Bool {
        return LogGlobalConfig.showWarningLog
    }
    /// Use global `Error` log config as default.
    public var showErrorLog: Bool {
        return LogGlobalConfig.showErrorLog
    }
    /// Use global `Debug` log config as default.
    public var showDebugLog: Bool {
        return LogGlobalConfig.showDebugLog
    }
    /// Use global `Info` log config as default.
    public var showInfoLog: Bool {
        return LogGlobalConfig.showInfoLog
    }
    /// Use global `Verbose` log config as default.
    public var showVerboseLog: Bool {
        return LogGlobalConfig.showVerboseLog
    }

    /// Function to log message to console.
    public func log(_ type: LogType, _ message: String) {

        switch type {
        case .WARNING where (showWarningLog == true || showVerboseLog == true):
            print("WARNING:", message)
        case .ERROR where (showErrorLog == true || showVerboseLog == true):
            print("ERROR:", message)
        case .DEBUG where (showDebugLog == true || showVerboseLog == true):
            print("DEBUG:", message)
        case .INFO where (showInfoLog == true || showVerboseLog == true):
            print("INFO:", message)
        case .VERBOSE where (showVerboseLog == true):
            print("VERBOSE:", message)
        default:
            break
        }
    }
}

extension Log { // Static version of the `Log` protocol extension

    /// Use global `Warning` log config as default
    public static var showWarningLog: Bool {
        return LogGlobalConfig.showWarningLog
    }
    /// Use global `Error` log config as default.
    public static var showErrorLog: Bool {
        return LogGlobalConfig.showErrorLog
    }
    /// Use global `Debug` log config as default.
    public static var showDebugLog: Bool {
        return LogGlobalConfig.showDebugLog
    }
    /// Use global `Info` log config as default.
    public static var showInfoLog: Bool {
        return LogGlobalConfig.showInfoLog
    }
    /// Use global `Verbose` log config as default.
    public static var showVerboseLog: Bool {
        return LogGlobalConfig.showVerboseLog
    }

    /// Function to log message to console.
    public static func log(_ type: LogType, _ message: String) {

        switch type {
        case .WARNING where (showWarningLog == true || showVerboseLog == true):
            print("WARNING:", message)
        case .ERROR where (showErrorLog == true || showVerboseLog == true):
            print("ERROR:", message)
        case .DEBUG where (showDebugLog == true || showVerboseLog == true):
            print("DEBUG:", message)
        case .INFO where (showInfoLog == true || showVerboseLog == true):
            print("INFO:", message)
        case .VERBOSE where (showVerboseLog == true):
            print("VERBOSE:", message)
        default:
            break
        }
    }
}

//-----------------------------------------------------------------------------------------------------------------
// MARK: - Type specific logging

/// Log type for data encoding and decoding.
///
/// - `JSONEncode`: enum case for json encode.
/// - `JSONDecode`: enum case for json decode.
public enum CoderType {
    /// Enum case for json encode.
    case JSONEncode
    /// Enum case for json decode.
    case JSONDecode
}

/// Log message when doing data encoding and decoding.
///
/// - Parameters:
///   - type: Coder type of encoding or decoding.
///   - message: message to print to the console.
public func logCoder(_ type: CoderType, _ message: String) {

    guard LogGlobalConfig.showCoderLog == true else {return}

    switch type {
    case .JSONEncode:
        print("JSONEncode:", message)
    case .JSONDecode:
        print("JSONDecode:", message)
    }
}

/// API type for api log.
///
/// - `request`: enum case for api request type.
/// - `response`: enum case for api response type.
public enum APIType {
    /// Enum case for api request type.
    case request
    /// Enum case for api response type.
    case response
}

/// Log api output when doing http request and response.
///
/// - Parameters:
///   - type: `APIType` for logging.
///   - url: `URL` for api output.
///   - output: output for http request and response.
public func logAPI(_ type: APIType, _ url: URL, output: Any) {

    guard LogGlobalConfig.showAPILog == true else {return}

    printSeparatorLine()

    switch type {
    case .request:
        print("API-Request:", url)
    default:
        print("API-Response", url)
    }

    printSeparatorLine()
    print(output)
    printSeparatorLine()
}

/// Log message when doing database transaction.
///
/// - Parameter message: message to print to the console.
public func logDatabase(_ message: String) {
    print("Database:", message)
}

//-----------------------------------------------------------------------------------------------------------------
// MARK: - Print separator

/// Print separator line to console.
///
/// - Parameters:
///   - pattern: Pattern for separator line, default "-"
///   - length: Length for separator line, default that repeat pattern 100 times.
public func printSeparatorLine(_ pattern: String = "-", _ length: Int = 100) {
    let separatorLine = String(repeating: pattern, count: length)
    print(separatorLine)
}

/// Get separator line string with new line.
///
/// - Parameters:
///   - pattern: Pattern for separator line, default "*"
///   - length: Length for separator line, default that repeat pattern 100 times.
/// - Returns: Separator line string with new line.
public func separatorWithNewLine(_ pattern: String = "*", _ length: Int = 100) -> String {
    return  "\n" + String(repeating: pattern, count: length) + "\n"
}
