//
//  RequestCancellation.swift
//  HTTPClient
//
//  Created by Min Wu on 09/02/2017.
//  Copyright © 2017 Min WU. All rights reserved.
//

import Foundation

/// Cancellation token object use to cancel request.
public class RequestCancellationToken {

    /// URL session task that can be cancel, it has weak reference.
    public internal(set) weak var task: URLSessionTask?

    /// Flag of the task that is cancelled.
    /// Use internally to stop callback for success/error completion handler
    public var isTaskCancelled: Bool {
        (self.task == nil)
    }

    /// Cancel and remove url sessoin task that is running or on queue
    public func cancel() {
        self.task?.cancel()
        self.task = nil
    }
}
