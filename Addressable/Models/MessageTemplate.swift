//
//  MessageTemplate.swift
//  Addressable
//
//  Created by Ari on 5/20/21.
//

// MARK: - MessageTemplatesResponse
struct MessageTemplatesResponse: Codable {
    let messageTemplates: [MessageTemplateResponse]

    enum CodingKeys: String, CodingKey {
        case messageTemplates = "message_templates"
    }
}

// MARK: - MessageTemplateResponse
struct MessageTemplateResponse: Codable {
    let messageTemplate: MessageTemplate

    enum CodingKeys: String, CodingKey {
        case messageTemplate = "message_template"
    }
}

// MARK: - MessageTemplate
struct MessageTemplate: Codable, Identifiable {
    let id: Int
    var title, body: String
    var mergeVars: [String]
    let owned: Bool?

    enum CodingKeys: String, CodingKey {
        case id, title, body
        case mergeVars = "merge_vars"
        case owned
    }
}
// MARK: - OutgoingMessageTemplateWrapper
struct OutgoingMessageTemplateWrapper: Codable {
    let messageTemplate: OutgoingMessageTemplate

    enum CodingKeys: String, CodingKey {
        case messageTemplate = "message_template"
    }
}

// MARK: - OutgoingMessageTemplate
struct OutgoingMessageTemplate: Codable {
    let title: String?
    let body: String

    enum CodingKeys: String, CodingKey {
        case title
        case body
    }
}
