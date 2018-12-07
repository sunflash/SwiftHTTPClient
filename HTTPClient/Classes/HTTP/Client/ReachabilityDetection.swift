//
//  ReachabilityDetection.swift
//  HTTPClient
//
//  Created by Min Wu on 23/02/2017.
//  Copyright © 2017 Min WU. All rights reserved.
//

import Foundation

/// Use to check if there any working network connections to specify hosts.
public class ReachabilityDetection {

    /// Shared instance of reachability detection
    public static let shared = ReachabilityDetection()

    private var reachabilities = [APReachability]()

    /// Reachability status completion handler
    public var reachabilityStatusCompletionHandlers: [String: (Bool) -> Void] = [String: (Bool)->Void]()

    /// Is internet available for reachability hosts.
    public var isInternetAvailable = false

    /// Hosts that is monitoring at the moment.
    public private(set) var monitoringHosts = [String]()

    init() {}

    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Reachability methodes

    /// Start reachability monitoring for hosts
    ///
    /// - Parameter hosts: Array of hosts that wish to do reachability monitoring
    /// - Returns: Status for reachability monitoring
    public func startReachabilityMonitoring(hosts: [String]) -> (success: Bool, description: String) {

        let urls = hosts.compactMap {URLComponents(string: $0)}

        guard urls.count == hosts.count else {
            return (false, "Hosts contains invalid domain host name")
        }

        if reachabilities.isEmpty == true {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(reachabilityChanged(notification:)),
                                                   name: Notification.Name.reachabilityChanged,
                                                   object: nil)
        }

        for hostName in urls.compactMap({$0.string}) {
            guard let reachability = APReachability(hostName: hostName) else {continue}
            reachability.startNotifier()
            self.reachabilities.append(reachability)
            self.monitoringHosts.append(hostName)
        }

        // Reachability takes couple of seconds to start up and detect connection status.
        // To avoid false report that internet is unavailable, we set isInternetAvailable to true to begin with.
        self.isInternetAvailable = true

        return (true, "Start reachability testing in \(hosts.joined(separator: ", "))")
    }

    /// Stop reachability monitoring for hosts
    public func stopReachabilityMonitoring() {

        reachabilities.forEach {$0.stopNotifier()}
        NotificationCenter.default.removeObserver(self, name: Notification.Name.reachabilityChanged, object: nil)
        self.reachabilities.removeAll()
        self.monitoringHosts.removeAll()
        self.reachabilityStatusCompletionHandlers.removeAll()
    }

    @objc private func reachabilityChanged(notification: Notification) {
        guard let currentReachability = notification.object as? APReachability else {return}

        self.updateReachabilityStat(reachability: currentReachability)
    }

    private func updateReachabilityStat(reachability: APReachability?) {

        self.isInternetAvailable = self.reachabilities.filter {$0.currentReachabilityStatus() != NotReachable}.isEmpty == false

        reachabilityStatusCompletionHandlers.values.forEach {
            $0(isInternetAvailable)
        }
    }

    deinit {
        self.stopReachabilityMonitoring()
    }
}
