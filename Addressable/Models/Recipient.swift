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
    let fullName, status, siteAddress, mailingAddress: String

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case status
        case siteAddress = "site_address"
        case mailingAddress = "mailing_address"
    }
}
// MARK: - OutgoingRecipientStatus
struct OutgoingRecipientStatus: Codable {
    let status: String

    enum CodingKeys: String, CodingKey {
        case status
    }
}
// MARK: - UpdateRecipientStatusResponse
struct UpdateRecipientStatusResponse: Codable {
    let message: String

    enum CodingKeys: String, CodingKey {
        case message
    }
}
// MARK: - RemoveRecipientResponse
struct RemoveRecipientResponse: Codable {
    let listEntry: ListEntry

    enum CodingKeys: String, CodingKey {
        case listEntry = "list_entry"
    }
}

// MARK: - ListEntry
struct ListEntry: Codable {
    let id: Int
    let status, toAddress, firstName, lastName: String
    let secondFirstName, secondLastName: String?
    let addressLine1, addressLine2, city, state: String
    let zipcode, zipLastFour, deliveryPointCode: String

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
