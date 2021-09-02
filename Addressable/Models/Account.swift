//
//  Account.swift
//  Addressable
//
//  Created by Ari on 9/1/21.
//

import Foundation

// MARK: - AccountResponse
struct AccountResponse: Codable {
    let account: Account
}

// MARK: - Account
struct Account: Codable {
    let id: Int
    let users: [User]
    let tokenCount: Int
    let radiusTokenCount: Int

    enum CodingKeys: String, CodingKey {
        case id, users
        case tokenCount = "token_count"
        case radiusTokenCount = "radius_token_count"
    }
}
