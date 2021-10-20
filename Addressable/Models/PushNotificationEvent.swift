//
//  PushNotificationEvent.swift
//  Addressable
//
//  Created by Ari on 10/19/21.
//

import Foundation

// MARK: - PushNotificationEvent
struct PushNotificationEvent: Codable, Equatable {
    static func == (lhs: PushNotificationEvent, rhs: PushNotificationEvent) -> Bool {
        lhs.mailingListStatus == rhs.mailingListStatus &&
            lhs.incomingLeadCall == rhs.incomingLeadCall &&
            lhs.incomingLeadMessage == rhs.incomingLeadMessage
    }

    let mailingListStatus: PushNotificationData?
    let incomingLeadCall: PushNotificationData?
    let incomingLeadMessage: PushNotificationData?

    enum CodingKeys: String, CodingKey {
        case mailingListStatus = "mailing_list_status"
        case incomingLeadCall = "incoming_lead_call"
        case incomingLeadMessage = "incoming_lead_message"
    }
}

// MARK: - PushNotificationData
struct PushNotificationData: Codable, Equatable {
    let leadId: Int?
    let mailingId: Int?
    let recordingUrl: String?

    enum CodingKeys: String, CodingKey {
        case leadId = "lead_id"
        case mailingId = "mailing_id"
        case recordingUrl = "recording_url"
    }
}
