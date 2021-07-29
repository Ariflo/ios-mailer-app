//
//  Authorization.swift
//  Addressable
//
//  Created by Ari on 1/4/21.
//

import Foundation

// MARK: - AuthorizedUserResponse
struct AuthorizedUserResponse: Codable {
    let firstName: String
    let lastName: String
    let userToken: String

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case userToken = "user_token"
    }
}

// MARK: - DeviceIDWrapper
struct DeviceIDWrapper: Codable {
    let deviceID: String

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
    }
}

// MARK: - GenericAPISuccessResponse
struct GenericAPISuccessResponse: Codable {
    let success: Bool

    enum CodingKeys: String, CodingKey {
        case success
    }
}
