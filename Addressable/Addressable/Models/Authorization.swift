//
//  Authorization.swift
//  Addressable
//
//  Created by Ari on 1/4/21.
//

import Foundation

struct AuthorizedUserResponse: Codable {
    let firstName: String
    let lastName: String

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

struct DeviceIDWrapper: Codable {
    let deviceID: String

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
    }
}
