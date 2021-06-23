//
//  Mailings.swift
//  Addressable
//
//  Created by Arian Flores on 12/3/20.
//

import SwiftUI

// MARK: - Mailing
struct Mailing: Codable {
    let id, accountID, userID: Int
    let name, createdAt, updatedAt: String
    let isCopyApproved, isAssetsApproved: Bool
    let targetQuantity, finalQuantity: Int
    let hubspotTicketID: Int?
    let subjectListEntryID: Int
    let multiTouchTopicID, parentMailingID: Int?
    let mailingOrder, priority, effort, confidence: Int
    let feasibility: Int
    let mailedZipcodes: String?
    let isMailed, manualList: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case accountID = "account_id"
        case userID = "user_id"
        case name
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isCopyApproved = "is_copy_approved"
        case isAssetsApproved = "is_assets_approved"
        case targetQuantity = "target_quantity"
        case finalQuantity = "final_quantity"
        case hubspotTicketID = "hubspot_ticket_id"
        case subjectListEntryID = "subject_list_entry_id"
        case multiTouchTopicID = "multi_touch_topic_id"
        case parentMailingID = "parent_mailing_id"
        case mailingOrder = "mailing_order"
        case priority, effort, confidence, feasibility
        case mailedZipcodes = "mailed_zipcodes"
        case isMailed = "is_mailed"
        case manualList = "manual_list"
    }
}

// MARK: - CampaignsResponse
struct CampaignsResponse: Codable {
    let campaigns: [Campaign]
}

// MARK: - Campaign
struct Campaign: Codable {
    let radiusMailing: RadiusMailing?

    enum CodingKeys: String, CodingKey {
        case radiusMailing = "radius_mailing"
    }
}
