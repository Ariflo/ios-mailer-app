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
    let md5, fromNumber, toNumber, firstName, lastName: String?
    let streetLine1, streetLine2, city, state: String?
    let zipcode, crmID: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id, md5
        case fromNumber = "from_number"
        case toNumber = "to_number"
        case firstName = "first_name"
        case lastName = "last_name"
        case streetLine1 = "street_line_1"
        case streetLine2 = "street_line_2"
        case city, state, zipcode
        case crmID = "crm_id"
        case status
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
