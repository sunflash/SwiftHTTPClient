//
//  DatabaseHelper.swift
//  HTTPClient
//
//  Created by Min Wu on 22/06/2017.
//  Copyright © 2017 Min Wu. All rights reserved.
//

import Foundation
import Security
import RealmSwift

/// Protocol that simplify database handling
public protocol DatabaseHelper {

    /// Database file name.
    static var databaseFileName: String {get}

    /// Database key identifier.
    static var encryptionKeyIdentifier: String {get}

    /// Whether encrypt local database or not
    static var encryptLocalDB: Bool {get set}

    /// Whether DB is read only. (optional, default is false)
    static var readOnly: Bool {get set}

    /// The current schema version. (optional, default to 0)
    static var schemaVersion: UInt64 {get set}

    /// The block which migrates the DB to the current version. (optional, default to empty)
    static var migrationBlock: MigrationBlock? {get set}

    /// Whether database should be deleted if schema migration is required. (optional, default is true)
    static var deleteDatabaseIfMigrationNeeded: Bool {get set}
}

extension DatabaseHelper {

    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Database configuration

    /// Database directory
    public static var databaseDirectory: URL {
        return URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
    }

    /// Realm file url
    private static var realmFileURL: URL {
        return databaseDirectory.appendingPathComponent("\(databaseFileName).realm")
    }

    /// Realm temporary file url when doing convertion
    private static var tempCopyFileURL: URL {
        return databaseDirectory.appendingPathComponent("\(databaseFileName)_temp.realm")
    }

    /// Whether DB is read only. (default is false)
    public static var readOnly: Bool {
        get {return false}
        set {}
    }

    /// The current schema version. (default to 0)
    public static var schemaVersion: UInt64 {
        get {return 0}
        set {}
    }

    /// The block which migrates the DB to the current version. (default to empty)
    public static var migrationBlock: MigrationBlock? {
        get {return {_, _ in }}
        set {}
    }

    /// Whether database should be deleted if schema migration is required. (default to true)
    public static var deleteDatabaseIfMigrationNeeded: Bool {
        get {return false}
        set {}
    }

    /// Default database configuration
    public static var defaultDatabaseConfiguration: Realm.Configuration {

        var configuration = Realm.Configuration()
        configuration.fileURL = realmFileURL
        configuration.encryptionKey = (encryptLocalDB == true) ? getEncryptionKey() : nil
        configuration.readOnly = readOnly
        configuration.schemaVersion = schemaVersion
        configuration.migrationBlock = migrationBlock
        configuration.deleteRealmIfMigrationNeeded = deleteDatabaseIfMigrationNeeded
        return configuration
    }

    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - Database methodes

    /// Get/Generate encryption key from/to keychain
    ///
    /// - Returns: 64 bit random encryption key as `Data`
    private static func getEncryptionKey() -> Data {

        // If realm db encryption key exist in keychain, then return the key.
        let keychainSwift = KeychainSwift()
        keychainSwift.synchronizable = true

        if let key = keychainSwift.getData(encryptionKeyIdentifier) {
            return key
        }

        // If realm db encryption key doesn't exist, generate a new key and save to the keychain.
        var key = Data(count: 64)
        _ = key.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 64, bytes)
        }
        keychainSwift.set(key, forKey: encryptionKeyIdentifier)

        return key
    }

    /// Get database instance
    ///
    /// - Parameter configuration: configuration for database, default to `defaultDatabaseConfiguration` if not specified
    /// - Returns: database instance
    public static func getDatabaseInstance(with configuration: Realm.Configuration = Self.defaultDatabaseConfiguration) -> Realm? {

        return autoreleasepool { () -> Realm? in
            do {
                return try Realm(configuration: configuration)
            } catch Realm.Error.fileAccess {
                return switchEncryption(configuration: configuration)
            } catch {
                return nil
            }
        }
    }

    /// Add or remove encryption to existing database
    ///
    /// - Parameter configuration: configuration for database
    /// - Returns: database instance
    private static func switchEncryption(configuration: Realm.Configuration) -> Realm? {

        if configuration.encryptionKey != nil {
            do {
                let realm = try addEncryptionToExistingRealm(configuration: configuration)
                logDatabase("Apply encryption to existing realm database success: \(databaseFileName)")
                return realm
            } catch {
                logDatabase("Apply encryption to existing realm database failed: \(databaseFileName)")
                logDatabase(error.localizedDescription)
                _ = removeDatabase()
                return nil
            }
        } else {
            do {
                let realm = try removeEncryptionToExistingRealm(configuration: configuration)
                logDatabase("Remove encryption to existing realm database success: \(databaseFileName)")
                return realm
            } catch {
                logDatabase("Remove encryption to existing realm database failed: \(databaseFileName)")
                logDatabase(error.localizedDescription)
                _ = removeDatabase()
                return nil
            }
        }
    }

    /// Add encryption to existing database
    ///
    /// - Parameter configuration: configuration for database
    /// - Returns: database instance
    /// - Throws: Add encryption to existing database failed
    private static func addEncryptionToExistingRealm(configuration: Realm.Configuration) throws -> Realm? {

        guard let key = configuration.encryptionKey else {return nil}
        var noEncryptConfiguration = configuration
        noEncryptConfiguration.encryptionKey = nil
        guard deleteFileIfExist(url: tempCopyFileURL) == true else {return nil}

        try autoreleasepool {
            let noEncryptRealm = try Realm(configuration: noEncryptConfiguration)
            try noEncryptRealm.writeCopy(toFile:tempCopyFileURL, encryptionKey:key)
        }

        guard deleteFileIfExist(url: realmFileURL) == true else {return nil}

        return try autoreleasepool { () -> Realm in
            try FileManager.default.moveItem(at: tempCopyFileURL, to: realmFileURL)
            var newConfiguration = configuration
            newConfiguration.encryptionKey = key
            return try Realm(configuration: newConfiguration)
        }
    }

    /// Remove encryption to existing database
    ///
    /// - Parameter configuration: configuration for database
    /// - Returns: database instance
    /// - Throws: Remove encryption to existing database failed
    private static func removeEncryptionToExistingRealm(configuration: Realm.Configuration) throws -> Realm? {

        guard configuration.encryptionKey == nil else {return nil}
        var encryptConfiguration = configuration
        encryptConfiguration.encryptionKey = getEncryptionKey()
        guard deleteFileIfExist(url: tempCopyFileURL) == true else {return nil}

        try autoreleasepool {
            let encryptRealm = try Realm(configuration: encryptConfiguration)
            try encryptRealm.writeCopy(toFile:tempCopyFileURL, encryptionKey:nil)
        }

        guard deleteFileIfExist(url: realmFileURL) == true else {return nil}

        return try autoreleasepool { () -> Realm in
            try FileManager.default.moveItem(at: tempCopyFileURL, to: realmFileURL)
            var newConfiguration = configuration
            newConfiguration.encryptionKey = nil
            return try Realm(configuration: newConfiguration)
        }
    }

    //-----------------------------------------------------------------------------------------------------------------
    // MARK: - File handling

    /// Remove database from device
    /// - Warning: Use with caution
    /// - Returns: Whether remove database is succeed or failed
    public static func removeDatabase() -> Bool {

        return deleteFileIfExist(url: realmFileURL)
    }

    private static func deleteFileIfExist(url: URL) -> Bool {

        if FileManager.default.fileExists(atPath: url.path) == false {
            return true
        }

        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            return false
        }
    }
}
