//
//  Messages.swift
//  Addressable
//
//  Created by Ari on 1/14/21.
//

struct MessagesResponse: Codable {
    let leadMessages: [String]
    let status: String

    enum CodingKeys: String, CodingKey {
        case leadMessages = "lead_messages"
        case status
    }
}
struct Message: Codable, Identifiable {
    let id, incomingLeadID: Int
    let body: String
    let isIncoming: Bool
    let messageSid, createdAt, updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case incomingLeadID = "incoming_lead_id"
        case body
        case isIncoming = "is_incoming"
        case messageSid = "message_sid"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct OutgoingMessageWrapper: Codable {
    let leadMessage: OutgoingMessage

    init(outgoingMessage: OutgoingMessage) {
        self.leadMessage = outgoingMessage
    }

    enum CodingKeys: String, CodingKey {
        case leadMessage = "lead_message"
    }
}

struct OutgoingMessage: Codable {
    let incomingLeadID: Int
    let body: String
    let isIncoming: Bool
    let messageSid: String

    init(incomingLeadID: Int, body: String, messageSid: String) {
        self.incomingLeadID = incomingLeadID
        self.body = body
        self.isIncoming = false
        self.messageSid = messageSid
    }

    enum CodingKeys: String, CodingKey {
        case incomingLeadID = "incoming_lead_id"
        case body
        case isIncoming = "is_incoming"
        case messageSid = "message_sid"
    }
}
