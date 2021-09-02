//
//  Handwriting.swift
//  Addressable
//
//  Created by Ari on 8/31/21.
//

import Foundation

// MARK: - HandwritingResponse
struct HandwritingResponse: Codable {
    let handwritings: [Handwriting]
}

// MARK: - Handwriting
struct Handwriting: Codable, Identifiable {
    let id: Int
    let name: String
}

// MARK: - UpdateHandwriting
struct UpdateHandwriting: Codable {
    let handwritingID: Int

    enum CodingKeys: String, CodingKey {
        case handwritingID = "handwriting_id"
    }
}
