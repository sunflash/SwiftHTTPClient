//
//  Collection+Extension.swift
//  HTTPClient
//
//  Created by Min Wu on 13/11/2016.
//  Copyright © 2017 Min Wu. All rights reserved.
//

import Foundation

extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    public subscript (safe index: Index) -> Iterator.Element? {
        index >= startIndex && index < endIndex ? self[index] : nil
    }

    /// Remove duplicate element from a collection
    public func filterDuplicates<T>(include: (T, T) -> Bool) -> [T] {
        var results = [T]()
        forEach { element in
            if let e = element as? T { // swiftlint:disable:this identifier_name
                let existingElements = results.filter {!include(e, $0)}
                if existingElements.isEmpty == true {results.append(e)}
            }
        }
        return results
    }
}
