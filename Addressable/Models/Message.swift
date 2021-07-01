//
//  Messages.swift
//  Addressable
//
//  Created by Ari on 1/14/21.
//

// MARK: - MessagesResponse
struct MessagesResponse: Codable {
    let leadMessages: [String]
    let status: String

    enum CodingKeys: String, CodingKey {
        case leadMessages = "lead_messages"
        case status
    }
}

// MARK: - Message
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

// MARK: - OutgoingMessageWrapper
struct OutgoingMessageWrapper: Codable {
    let leadMessage: OutgoingMessage

    init(outgoingMessage: OutgoingMessage) {
        self.leadMessage = outgoingMessage
    }

    enum CodingKeys: String, CodingKey {
        case leadMessage = "lead_message"
    }
}

// MARK: - OutgoingMessage
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
// MARK: - MessageSocketCommand
struct MessageSocketCommand: Codable {
    let command, identifier: String
}
// MARK: - MessageSubscribeResponse
struct MessageSubscribeResponse: Codable {
    let identifier: String?
    let message: MessagesResponse?
    let type: SocketReponseTypes?
}

// MARK: - MessageSubscribeResponse
struct MessageSubscribePingResponse: Codable {
    let identifier: String?
    let message: Int?
    let type: SocketReponseTypes?
}
