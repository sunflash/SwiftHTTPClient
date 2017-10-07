//
//  Dictionary+Extension.swift
//  Mappable
//
//  Created by Min Wu on 23/05/2017.
//  Copyright © 2017 Min Wu. All rights reserved.
//

import Foundation

extension Dictionary {

    /// Dictionary `+` operator for combine two dictionary into one.
    /// - Note: There is `no` handling for `duplicate`, duplicate on the right side would replaceing values on the left side, should use with caution.
    /// In case duplicate handing is require, don't use this methode.
    /// - Parameters:
    ///   - lhs: dictionary on the left side of the operator.
    ///   - rhs: dictionary on the right side of the operator.
    /// - Returns: New dictionary with combining values of two dictionary.
    static public func + (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
        var result = lhs
        for (key, value) in rhs {
            result[key] = value
        }
        return result
    }

    /// Dictionary `+=` operator for combine two dictionary into one.
    /// - Note: There is `no` handling for `duplicate`, duplicate on the right side would replaceing values on the left side, should use with caution.
    /// In case duplicate handing is require, don't use this methode.
    /// - Parameters:
    ///   - left: dictionary on the left side of the operator that including values of dictionary from right side.
    ///   - right: dictionary on the right side of the operator.
    static public func += (left: inout [Key: Value], right: [Key: Value]) {
        right.forEach {left[$0.key] = $0.value}
    }
}
