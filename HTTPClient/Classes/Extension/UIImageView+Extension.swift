//
//  UIImageView+Extension.swift
//  HTTPClient
//
//  Created by Min Wu on 07/05/2017.
//  Copyright © 2017 Min WU. All rights reserved.
//

import Foundation
import UIKit

/// Extension to `UIImageView`
extension UIImageView {

    /// Convenience function to display image from web url
    ///
    /// - Parameters:
    ///   - url: url for image
    ///   - placeholder: placeholder image, optional
    public func displayImage(from url: URL, withPlaceholder placeholder: UIImage? = nil) {
        self.image = placeholder
        URLSession.shared.dataTask(with: url) { (data, _, _) in
            guard let imageData = data, let image = UIImage(data: imageData) else {return}
            GCD.main.queue.async {self.image = image}
        }.resume()
    }
}
