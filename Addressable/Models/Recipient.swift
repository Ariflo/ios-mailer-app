//
//  Recipient.swift
//  Addressable
//
//  Created by Ari on 5/20/21.
//

// MARK: - RecipientResponse
struct RecipientResponse: Codable {
    let recipients: [Recipient]

    enum CodingKeys: String, CodingKey {
        case recipients
    }
}

// MARK: - Recipient
struct Recipient: Codable, Identifiable {
    let id: Int
    let fullName, listMembership, siteAddress, mailingAddress: String

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case listMembership = "list_membership"
        case siteAddress = "site_address"
        case mailingAddress = "mailing_address"
    }
}
// MARK: - OutgoingRecipientStatus
struct OutgoingRecipientStatus: Codable {
    let listMembership: String

    enum CodingKeys: String, CodingKey {
        case listMembership = "list_membership"
    }
}
// MARK: - UpdateRecipientResponse
struct UpdateRecipientResponse: Codable {
    let listEntry: ListEntry

    enum CodingKeys: String, CodingKey {
        case listEntry = "list_entry"
    }
}

// MARK: - ListEntry
struct ListEntry: Codable {
    let id: Int
    let status: String?
    let toAddress, firstName, lastName: String?
    let secondFirstName, secondLastName: String?
    let addressLine1: String
    let addressLine2: String?
    let city, state, zipcode, zipLastFour: String
    let deliveryPointCode: String

    enum CodingKeys: String, CodingKey {
        case id, status
        case toAddress = "to_address"
        case firstName = "first_name"
        case lastName = "last_name"
        case secondFirstName = "second_first_name"
        case secondLastName = "second_last_name"
        case addressLine1 = "address_line_1"
        case addressLine2 = "address_line_2"
        case city, state, zipcode
        case zipLastFour = "zip_last_four"
        case deliveryPointCode = "delivery_point_code"
    }
}
