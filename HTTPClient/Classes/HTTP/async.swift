//
//  async.swift
//  HTTPClient
//
//  Created by Min Wu on 09/02/2017.
//  Copyright © 2017 Min WU. All rights reserved.
//

import Foundation

/**
 `GCD` is a convenience enum with cases to get `DispatchQueue` of different quality of service classes, 
 as provided by `DispatchQueue.global` or `DispatchQueue` for main thread or a specific custom queue.
 */
public enum GCD {

    /// Main queue
    case main
    /// User interactive queue
    case userInteractive
    /// User initiated queue
    case userInitiated
    /// Utility queue
    case utility
    /// Background queue
    case background
    /// Custom queue
    case custom(queue: DispatchQueue)

    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Convenience property and method

    /// Convenience property to get specific queue "GCD.main.queue.async"
    public var queue: DispatchQueue {
        switch self {
        case .main:
            return .main
        case .userInteractive:
            return .global(qos: .userInteractive)
        case .userInitiated:
            return .global(qos: .userInitiated)
        case .utility:
            return .global(qos: .utility)
        case .background:
            return .global(qos: .background)
        case .custom(let queue):
            return queue
        }
    }

    /// Convenience methode for invoke GCG queue with delay "GCD.main.after(delay: 0.1)"
    public func after(delay: Double, closure: @escaping () -> Void ) {

        self.queue.asyncAfter(deadline: .now() + delay) {
            closure()
        }
    }
}
