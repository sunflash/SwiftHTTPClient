import Foundation
import HTTPClient

public struct Profile: Mappable {

    public internal(set) var id: Int?// swiftlint:disable:this identifier_name

    public var title: String?

    public var firstName: String?

    public var lastName: String?

    public var gender: String?

    public var dob: Date?

    public var email: String?

    public var mobile: Mobile?

    public var address: [Address]?

    public init() {}
    public var propertyValues: [String: Any] {return propertyValuesRaw}
}

public struct Mobile: Mappable {

    public var country: String?

    public var number: String?

    public init() {}
    public var propertyValues: [String: Any] {return propertyValuesRaw}
}

public struct Address: Mappable {

    var type: String?

    var zipCode: Int?

    var city: String?

    var country: String?

    public init() {}
    public var propertyValues: [String: Any] {return propertyValuesRaw}
}
