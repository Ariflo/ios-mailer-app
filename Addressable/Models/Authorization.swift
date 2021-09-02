//
//  Authorization.swift
//  Addressable
//
//  Created by Ari on 1/4/21.
//

import Foundation

// MARK: - AuthorizedUserResponse
struct AuthorizedUserResponse: Codable {
    let user: User
}

// MARK: - User
struct User: Codable, Identifiable {
    let id: Int
    let email, status: String
    let photo: String?
    let firstName, lastName: String
    let accountID: Int
    let dre: String?
    let phone, companyName, addressLine1, addressLine2: String
    let city, state, zipcode, authenticationToken: String
    let handwritingID: Int
    let messageTemplateID, defaultLayoutTemplateID: Int?

    enum CodingKeys: String, CodingKey {
        case id, email, status, photo
        case firstName = "first_name"
        case lastName = "last_name"
        case accountID = "account_id"
        case dre
        case phone
        case companyName = "company_name"
        case addressLine1 = "address_line_1"
        case addressLine2 = "address_line_2"
        case city, state, zipcode
        case authenticationToken = "authentication_token"
        case handwritingID = "handwriting_id"
        case messageTemplateID = "message_template_id"
        case defaultLayoutTemplateID = "default_layout_template_id"
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

// MARK: - UpdateUserAddress
struct UpdateUserAddress: Codable {
    let firstName, lastName: String
    let dre: String
    let companyName, addressLine1, addressLine2: String
    let city, state, zipcode: String

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case dre
        case companyName = "company_name"
        case addressLine1 = "address_line_1"
        case addressLine2 = "address_line_2"
        case city, state, zipcode
    }
}
