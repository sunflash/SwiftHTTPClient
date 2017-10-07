//
//  ProfileDBModel.swift
//  HTTPClientTests
//
//  Created by Min Wu on 08/10/2017.
//  Copyright © 2017 Min Wu. All rights reserved.
//

import Foundation
import RealmSwift

// MARK: - Realm Object (2017-10-07 23:41:21 +0000)

class RealmProfile: Object {

    @objc dynamic var dob: Date?

    @objc dynamic var email: String?

    @objc dynamic var firstName: String?

    @objc dynamic var gender: String?

    @objc dynamic var identifier = 0

    @objc dynamic var lastName: String?

    @objc dynamic var mobile: RealmMobile?

    @objc dynamic var title: String?

    let address = List<RealmAddress>()

    override static func primaryKey() -> String? {
        return "identifier"
    }
}

class RealmAddress: Object {

    @objc dynamic var city: String?

    @objc dynamic var country: String?

    @objc dynamic var identifier: String?

    @objc dynamic var type: String?

    let zipCode = RealmOptional<Int>()

    override static func primaryKey() -> String? {
        return "identifier"
    }
}

class RealmMobile: Object {

    @objc dynamic var country: String?

    @objc dynamic var identifier = 0

    @objc dynamic var number: String?

    override static func primaryKey() -> String? {
        return "identifier"
    }
}

// MARK: - Map to Realm (2017-10-07 23:41:21 +0000)

extension Profile {

    /// Create `RealmProfile` object from `Profile` struct
    ///
    /// - Returns: `RealmProfile` object
    func toRealmObject() -> RealmProfile {

        let realmProfile = RealmProfile()
        self.address?.forEach {realmProfile.address.append($0.toRealmObject())}
        realmProfile.dob = self.dob
        realmProfile.email = self.email
        realmProfile.firstName = self.firstName
        realmProfile.gender = self.gender
        realmProfile.identifier = self.id ?? 0
        realmProfile.lastName = self.lastName
        realmProfile.mobile = self.mobile?.toRealmObject()
        realmProfile.title = self.title

        // Set primary key for nested object and object array
        realmProfile.address.forEach {
            $0.identifier = "\(self.id ?? 0)-\($0.type ?? "")"
        }
        realmProfile.mobile?.identifier = self.id ?? 0
        return realmProfile
    }
}

extension Address {

    /// Create `RealmAddress` object from `Address` struct
    ///
    /// - Returns: `RealmAddress` object
    func toRealmObject() -> RealmAddress {

        let realmAddress = RealmAddress()
        realmAddress.city = self.city
        realmAddress.country = self.country
        realmAddress.type = self.type
        realmAddress.zipCode.value = self.zipCode
        return realmAddress
    }
}

extension Mobile {

    /// Create `RealmMobile` object from `Mobile` struct
    ///
    /// - Returns: `RealmMobile` object
    func toRealmObject() -> RealmMobile {

        let realmMobile = RealmMobile()
        realmMobile.country = self.country
        realmMobile.number = self.number
        return realmMobile
    }
}

// MARK: - Map from Realm (2017-10-07 23:41:21 +0000)

extension RealmProfile {

    /// Create `Profile` struct from `RealmProfile` object
    ///
    /// - Returns: `Profile` struct
    func toProfile() -> Profile {

        var profile = Profile()
        profile.address = self.address.flatMap {$0.toAddress()}
        profile.dob = self.dob
        profile.email = self.email
        profile.firstName = self.firstName
        profile.gender = self.gender
        profile.id = self.identifier
        profile.lastName = self.lastName
        profile.mobile = self.mobile?.toMobile()
        profile.title = self.title
        return profile
    }
}

extension RealmAddress {

    /// Create `Address` struct from `RealmAddress` object
    ///
    /// - Returns: `Address` struct
    func toAddress() -> Address {

        var address = Address()
        address.city = self.city
        address.country = self.country
        address.type = self.type
        address.zipCode = self.zipCode.value
        return address
    }
}

extension RealmMobile {

    /// Create `Mobile` struct from `RealmMobile` object
    ///
    /// - Returns: `Mobile` struct
    func toMobile() -> Mobile {

        var mobile = Mobile()
        mobile.country = self.country
        mobile.number = self.number
        return mobile
    }
}
