//
//  MailingCoverImage.swift
//  Addressable
//
//  Created by Ari on 5/20/21.
//

import SwiftUI

// MARK: - MailingCoverImageResponse
struct MailingCoverImageResponse: Codable {
    let mailingCoverImages: [MailingCoverImageMap]

    enum CodingKeys: String, CodingKey {
        case mailingCoverImages = "layout_templates"
    }
}

// MARK: - MailingCoverImageMap
struct MailingCoverImageMap: Codable {
    let mailingCoverImage: MailingCoverImage

    enum CodingKeys: String, CodingKey {
        case mailingCoverImage = "layout_template"
    }
}
// MARK: - MailingCoverArt
struct MailingCoverImage: Codable, Identifiable, Equatable {
    let id: Int
    let name: String?
    let pdfUrl: String?
    let imageUrl: String?
    let cardFrontImageUrl: String?
    let cardBackImageUrl: String?
    let isDefaultCoverImage: Bool

    enum CodingKeys: String, CodingKey {
        case id, name
        case pdfUrl = "pdf_url"
        case imageUrl = "image_url"
        case cardFrontImageUrl = "card_front_url"
        case cardBackImageUrl = "card_back_url"
        case isDefaultCoverImage = "is_default_cover_image"
    }
}

// MARK: - MailingCoverImageData
struct MailingCoverImageData: Codable, Identifiable {
    let id: Int
    let image: MailingCoverImage
    let imageData: Data

    enum CodingKeys: String, CodingKey {
        case id, image, imageData
    }
}
