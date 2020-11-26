//
//  String+Extension.swift
//  HTTPClient
//
//  Created by Min Wu on 02/06/2017.
//  Copyright © 2017 Min Wu. All rights reserved.
//

import Foundation

extension String {

    func split(by string: String) -> [String] {
        self.trimmingCharacters(in: .whitespaces).split(separator: Character(string)).map {String($0)}
    }
}
