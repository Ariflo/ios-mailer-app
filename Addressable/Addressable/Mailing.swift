//
//  Mailing.swift
//  Addressable
//
//  Created by Arian Flores on 12/3/20.
//

import Foundation

struct MailingsResponse: Codable {
    let mailings: [MailingElement]
}

struct MailingElement: Codable {
    let mailing: MailingMailing
}

struct MailingMailing: Codable, Identifiable {
    let id: Int
    let name: String
    let phone, email: String?

    enum CodingKeys: String, CodingKey {
        case id, name, phone, email
    }
}
