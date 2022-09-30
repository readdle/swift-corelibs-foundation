//
// Created by Andriy Druk on 03.12.2019.
//

import Foundation

public enum AvatarType: Int, Hashable, Codable {
    case human
    case newsletter
    case service
}

public struct AddressAvatarsRequest: AvatarRequest, Hashable, Codable {

    public let email: String
    public let type: AvatarType?

    public init(email: String, type: AvatarType?) {
        self.email = email
        self.type = type
    }

    public var key: String {
        return "\(email)\(type?.rawValue ?? -1)"
    }
}
