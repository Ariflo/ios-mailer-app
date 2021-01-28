//
//  Mailings.swift
//  Addressable
//
//  Created by Arian Flores on 12/3/20.
//

import SwiftUI
import Combine

// MARK: - MailingsResponse
struct MailingsResponse: Codable {
    let mailings: [MailingElement]

    enum CodingKeys: String, CodingKey {
        case mailings
    }
}

// MARK: - MailingElement
struct MailingElement: Codable {
    let mailing: AddressableMailing

    enum CodingKeys: String, CodingKey {
        case mailing
    }
}

// MARK: - AddressableMailing
struct AddressableMailing: Codable, Identifiable {
    let id: Int
    let name: String
    let phone, email: String?

    enum CodingKeys: String, CodingKey {
        case id, name, phone, email
    }
}

// MARK: - CustomNotesResponse
struct CustomNotesResponse: Codable {
    let customNotes: [CustomNotes]

    enum CodingKeys: String, CodingKey {
        case customNotes = "custom_notes"
    }
}

// MARK: - CustomNotes
struct CustomNotes: Codable {
    let customNote: CustomNote

    enum CodingKeys: String, CodingKey {
        case customNote = "custom_note"
    }
}

// MARK: - CustomNote
struct CustomNote: Codable, Identifiable {
    let id: Int
    let body, toFirstName, toLastName, toBusinessName: String?
    let toToLine, toAttnLine: String?
    let toAddressLine1, toAddressLine2, toCity, toState: String?
    let toZipcode, fromFirstName, fromLastName, fromBusinessName: String?
    let fromToLine, fromAttnLine: String?
    let fromAddressLine1, fromAddressLine2, fromCity, fromState: String?
    let fromZipcode: String?
    let handwritingID: Int?
    let status: String?
    let cardType, format, mediaSize: String?
    let messageTemplateID: Int?
    let batchSize: Int

    enum CodingKeys: String, CodingKey {
        case id, body
        case toFirstName = "to_first_name"
        case toLastName = "to_last_name"
        case toBusinessName = "to_business_name"
        case toToLine = "to_to_line"
        case toAttnLine = "to_attn_line"
        case toAddressLine1 = "to_address_line_1"
        case toAddressLine2 = "to_address_line_2"
        case toCity = "to_city"
        case toState = "to_state"
        case toZipcode = "to_zipcode"
        case fromFirstName = "from_first_name"
        case fromLastName = "from_last_name"
        case fromBusinessName = "from_business_name"
        case fromToLine = "from_to_line"
        case fromAttnLine = "from_attn_line"
        case fromAddressLine1 = "from_address_line_1"
        case fromAddressLine2 = "from_address_line_2"
        case fromCity = "from_city"
        case fromState = "from_state"
        case fromZipcode = "from_zipcode"
        case handwritingID = "handwriting_id"
        case status
        case cardType = "card_type"
        case format
        case mediaSize = "media_size"
        case messageTemplateID = "message_template_id"
        case batchSize = "batch_size"
    }
}
// MARK: - OutGoingCustomNoteWrapper
struct OutGoingCustomNoteWrapper: Codable {
    let customNote: OutgoingCustomNote

    enum CodingKeys: String, CodingKey {
        case customNote = "custom_note"
    }
}

// MARK: - OutGoingCustomNote
struct OutgoingCustomNote: Codable {
    let toFirstName, toLastName: String
    let toBusinessName: String?
    let toAddressLine1: String
    let toAddressLine2: String?
    let toCity, toState, toZipcode: String
    let body: String
    let selectedCoverArtID: Int?
    let selectedMessageTemplateID: Int?
    let fromFirstName, fromLastName: String
    let fromBusinessName: String?
    let fromAddressLine1: String
    let fromAddressLine2: String?
    let fromCity, fromState, fromZipcode: String
    let cardType: String

    enum CodingKeys: String, CodingKey {
        case body
        case toFirstName = "to_first_name"
        case toLastName = "to_last_name"
        case toBusinessName = "to_business_name"
        case toAddressLine1 = "to_address_line_1"
        case toAddressLine2 = "to_address_line_2"
        case toCity = "to_city"
        case toState = "to_state"
        case toZipcode = "to_zipcode"
        case selectedCoverArtID = "layout_template_id"
        case selectedMessageTemplateID = "message_template_id"
        case fromFirstName = "from_first_name"
        case fromLastName = "from_last_name"
        case fromBusinessName = "from_business_name"
        case fromAddressLine1 = "from_address_line_1"
        case fromAddressLine2 = "from_address_line_2"
        case fromCity = "from_city"
        case fromState = "from_state"
        case fromZipcode = "from_zipcode"
        case cardType = "card_type"
    }
}

// MARK: - MailingCoverArtResponse
struct MailingCoverArtResponse: Codable {
    let mailingCoverArts: [MailingCoverArts]

    enum CodingKeys: String, CodingKey {
        case mailingCoverArts = "layout_templates"
    }
}

// MARK: - MailingCoverArts
struct MailingCoverArts: Codable {
    let mailingCoverArt: MailingCoverArt

    enum CodingKeys: String, CodingKey {
        case mailingCoverArt = "layout_template"
    }
}
// MARK: - MailingCoverArt
struct MailingCoverArt: Codable, Identifiable {
    let id: Int?
    let name: String?
    let pdfUrl: String?
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case pdfUrl = "pdf_url"
        case imageUrl = "image_url"
    }
}
// MARK: - CustomNote.CoverImage
extension CustomNote {
    struct CoverImage: View {
        @ObservedObject var imageLoader: ImageLoader
        @State var image = UIImage()
        let size: CGFloat
        let cornerRadius: CGFloat


        init(withURL url: String, size: CGFloat, cornerRadius: CGFloat) {
            imageLoader = ImageLoader(urlString: url)
            self.size = size
            self.cornerRadius = cornerRadius
        }

        var body: some View {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .cornerRadius(cornerRadius)
                .onReceive(imageLoader.didChange) { data in
                    self.image = UIImage(data: data) ?? UIImage(systemName: "exclamationmark.triangle")!
                }
        }
    }
}

// MARK: - ReturnAddress
struct ReturnAddress: Codable {
    let firstName, lastName, companyName, addressLine1: String
    let addressLine2, city, state, zipcode: String

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case companyName = "company_name"
        case addressLine1 = "address_line_1"
        case addressLine2 = "address_line_2"
        case city, state, zipcode
    }
}
// MARK: - MessageTemplatesResponse
struct MessageTemplatesResponse: Codable {
    let messageTemplates: [MessageTemplateElement]

    enum CodingKeys: String, CodingKey {
        case messageTemplates = "message_templates"
    }
}

// MARK: - MessageTemplateElement
struct MessageTemplateElement: Codable {
    let messageTemplate: MessageTemplate

    enum CodingKeys: String, CodingKey {
        case messageTemplate = "message_template"
    }
}

// MARK: - MessageTemplateMessageTemplate
struct MessageTemplate: Codable, Identifiable {
    let id: Int
    let title, body: String
    let mergeVars: [String]
    let owned: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, body
        case mergeVars = "merge_vars"
        case owned
    }
}
