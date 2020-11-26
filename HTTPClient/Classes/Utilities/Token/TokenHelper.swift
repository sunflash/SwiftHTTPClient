//
//  TokenHelper.swift
//  HTTPClient
//
//  Created by Min Wu on 31/08/2017.
//  Copyright © 2017 Min Wu. All rights reserved.
//

import Foundation
import KeychainSwift

/// Token helper class
public class TokenHelper: Log {

    //---------------------------------------------------------------------------------------------------------
    // MARK: - Token helper configuration

    /// Prefix for token storage in keychain
    public var keychainPrefix: String?

    /// Token persistence key in keychain
    public var tokenPersistenceKey: String

    /// Configure token handler, optional
    ///
    /// - Note: By register to this action handler, code block will be invoke when token is configure.
    ///
    public var configureTokenHandler: ((String) -> Void)?

    /// Configure clear token handler, optional
    ///
    /// - Note: By register to this action handler, code block will be invoke when clear token event happen.
    ///
    public var clearTokenHandler: (() -> Void)?

    /// Token expire handler, optional
    ///
    /// - Note: By register to this action handler, code block will be invoke when token expire event happen.
    ///
    public var tokenExpiredHandler: (() -> Void)?

    //---------------------------------------------------------------------------------------------------------
    // MARK: - Token helper internal configuration

    /// Token header name from backend
    private let tokenHeaderName = "Authorization"

    /// Existing token that is in use at the moment, use for comparison for token change and detect token update.
    private var existingToken: String?

    //---------------------------------------------------------------------------------------------------------
    // MARK: - Token helper init

    /// Init token help class
    ///
    /// - Parameter tokenPersistenceKey: Token persistence key in keychain
    public init(tokenPersistenceKey: String) {
        self.tokenPersistenceKey = tokenPersistenceKey
    }

    //---------------------------------------------------------------------------------------------------------
    // MARK: - Token helper methode

    /// Configure token with `HTTPResponse`
    ///
    /// - Parameter response: `HTTPResponse`
    public func configureToken(response: HTTPResponse) {

        guard let accessToken = response.headers[tokenHeaderName] else {
            return
        }

        if let currentToken = existingToken, currentToken == accessToken {
            // Token is not change, so we do nothing, keeping existing token and return early
            return
        }

        let keychain = KeychainSwift(keyPrefix: keychainPrefix ?? "")
        keychain.synchronizable = false
        keychain.set(accessToken, forKey: tokenPersistenceKey)
        configureTokenHandler?(accessToken)
        schedulerTokenExpireCheck(accessToken)
        existingToken = accessToken
    }

    /// Check current token is valid
    ///
    /// - Returns: whether current token is still valid.
    public func isCurrentTokenValid() -> Bool {

        let keychain = KeychainSwift(keyPrefix: keychainPrefix ?? "")
        keychain.synchronizable = false

        if let accessToken = keychain.get(tokenPersistenceKey), isTokenExpired(accessToken) == false {
            configureTokenHandler?(accessToken)
            schedulerTokenExpireCheck(accessToken)
            existingToken = accessToken
            return true
        } else {
            return false
        }
    }

    /// Clear token that is in used.
    public func clearToken() {

        let keychain = KeychainSwift(keyPrefix: keychainPrefix ?? "")
        keychain.synchronizable = false

        if keychain.get(tokenPersistenceKey) != nil {
            keychain.delete(tokenPersistenceKey)
        }
        self.timer?.invalidate()
        self.timer = nil
        clearTokenHandler?()
    }

    /// Check whether token is expired
    ///
    /// - Parameter token: access token (JWT)
    /// - Returns: whether token is expired
    private func isTokenExpired(_ token: String) -> Bool {

        guard let payload = try? JWTInfo.decodePayload(token), let tokenExpireDate = payload.expiration else {return false}

        if tokenExpireDate.timeIntervalSinceNow <= checkTokenExpireTimeInterval {
            // Token will expired soon
            clearToken()
            return true
        } else {
            return false
        }
    }

    //---------------------------------------------------------------------------------------------------------
    // MARK: - Check token expire timer

    /// Check token expired time interval (default to 60 sec, can adjust or use lower value for testing purpose)
    public var checkTokenExpireTimeInterval: TimeInterval = 60

    /// Check token expired timer
    private var timer: Timer?

    /// Schedule token expire check
    ///
    /// - Parameter token: access token
    public func schedulerTokenExpireCheck(_ token: String) {

        GCD.main.queue.async {
            // Clean old timer
            self.timer?.invalidate()
            self.timer = nil
            // Schedule new timer
            self.timer = Timer.scheduledTimer(timeInterval: self.checkTokenExpireTimeInterval,
                                              target: self,
                                              selector: #selector(self.checkTokenForExpire(_:)),
                                              userInfo: token,
                                              repeats: true)
            self.timer?.fire()
        }
    }

    /// Selector methode that check token for expire, invoke by timer.
    ///
    /// - Parameter timer: Check token expire timer
    @objc func checkTokenForExpire(_ timer: Timer) {

        guard let token = timer.userInfo as? String else {return}
        if isTokenExpired(token) == true {
            log(.WARNING, "Access token will expired soon.")
            tokenExpiredHandler?()
        }
    }
}
