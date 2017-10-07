//
//  String+Extension.swift
//  HTTPClient
//
//  Created by Min Wu on 02/06/2017.
//  Copyright © 2017 Min Wu. All rights reserved.
//

import Foundation

extension String {

    func split(by string: String) -> [String] { // swiftlint:disable:this identifier_name
        #if swift(>=4)
            return self.trimmingCharacters(in: .whitespaces).split(separator: Character(string)).map {String($0)}
        #else
            return self.trimmingCharacters(in: .whitespaces).components(separatedBy: string)
        #endif
    }
}
