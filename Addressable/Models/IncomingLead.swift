//
//  IncomingLead.swift
//  Addressable
//
//  Created by Ari on 1/13/21.
//

import Foundation

// MARK: - IncomingLead
struct IncomingLead: Codable, Identifiable {
    let id: Int
    let userID: Int
    let accountID: Int
    let createdAt: String
    let md5, fromNumber, toNumber, firstName, lastName: String?
    let streetLine1, streetLine2, city, state: String?
    let zipcode, crmID: String?
    let status: String?
    let qualityScore: Int?
    let userNotes: [UserNote]
    let voicemailUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case accountID = "account_id"
        case createdAt = "created_at"
        case md5
        case fromNumber = "from_number"
        case toNumber = "to_number"
        case firstName = "first_name"
        case lastName = "last_name"
        case streetLine1 = "street_line_1"
        case streetLine2 = "street_line_2"
        case city, state, zipcode
        case crmID = "crm_id"
        case status
        case qualityScore = "quality_score"
        case userNotes = "user_notes"
        case voicemailUrl = "voicemail_url"
    }
}

// MARK: - IncomingLeadResponse
struct IncomingLeadResponse: Codable {
    let incomingLead: IncomingLead

    enum CodingKeys: String, CodingKey {
        case incomingLead = "incoming_lead"
    }
}

// MARK: - IncomingLeadsResponse
typealias IncomingLeadsResponse = [IncomingLead]

// MARK: - OutgoingIncomingLead
struct TagIncomingLeadWrapper: Codable {
    let incomingLead: IncomingLeadTag

    enum CodingKeys: String, CodingKey {
        case incomingLead = "incoming_lead"
    }
}

// MARK: - IncomingLeadTag
struct IncomingLeadTag: Codable {
    let spam: String
    let qualityScore: Int
    let removal: String

    enum CodingKeys: String, CodingKey {
        case spam
        case qualityScore = "quality_score"
        case removal
    }
}
// MARK: - UserNote
struct UserNote: Codable, Identifiable {
    let id, userID: Int
    let userName: String
    let note, notableType: String
    let notableID: Int
    let createdAt, updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case userName = "user_name"
        case note
        case notableType = "notable_type"
        case notableID = "notable_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
// MARK: - OutgoingUserNote
struct OutgoingUserNote: Codable {
    let note: Note
}

// MARK: - Note
struct Note: Codable {
    let userID: Int
    let note: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case note
    }
}
