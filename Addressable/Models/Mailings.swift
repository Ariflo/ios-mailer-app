//
//  Mailings.swift
//  Addressable
//
//  Created by Arian Flores on 12/3/20.
//

import SwiftUI
import Combine

// MARK: - CampaignsResponse
struct CampaignsResponse: Codable {
    let campaigns: [Campaign]
}

// MARK: - Campaign
struct Campaign: Codable {
    let customNote: CustomNote?
    let radiusMailing: RadiusMailing?

    enum CodingKeys: String, CodingKey {
        case customNote = "custom_note"
        case radiusMailing = "radius_mailing"
    }
}
// MARK: - RadiusMailingWrapper
struct RadiusMailingWrapper: Codable {
    let radiusMailing: RadiusMailing

    enum CodingKeys: String, CodingKey {
        case radiusMailing = "radius_mailing"
    }
}

// MARK: - RadiusMailing
struct RadiusMailing: Codable {
    let account: Account
    let user: User
    let name, status: String
    let listCount: Int
    let recipients: [SubjectListEntry]
    let targetQuantity, activeRecipientCount: Int
    let layoutTemplate: LayoutTemplate?
    let parentMailingID: Int
    let radiusTemplateID: Int?
    let subjectListEntry: SubjectListEntry
    let topicDuration: Int?

    enum CodingKeys: String, CodingKey {
        case account, user, name, status
        case listCount = "list_count"
        case recipients
        case targetQuantity = "target_quantity"
        case activeRecipientCount = "active_recipient_count"
        case layoutTemplate = "layout_template"
        case parentMailingID = "parent_mailing_id"
        case radiusTemplateID = "radius_template_id"
        case subjectListEntry = "subject_list_entry"
        case topicDuration = "topic_duration"
    }
}

// MARK: - OutgoingRadiusMailingCoverArtWrapper
struct OutgoingRadiusMailingCoverArtWrapper: Codable {
    let cover: OutgoingRadiusMailingCoverArtData

    enum CodingKeys: String, CodingKey {
        case cover
    }
}

// MARK: - OutgoingRadiusMailingCoverArtData
struct OutgoingRadiusMailingCoverArtData: Codable {
    let layoutTemplateID: Int

    enum CodingKeys: String, CodingKey {
        case layoutTemplateID = "layout_template_id"
    }
}

// MARK: - OutgoingRadiusMailingCoverArtWrapper
struct OutgoingRadiusMailingTopicWrapper: Codable {
    let topic: OutgoingRadiusMailingTopicData

    enum CodingKeys: String, CodingKey {
        case topic
    }
}
// MARK: - OutgoingRadiusMailingTopicData
struct OutgoingRadiusMailingTopicData: Codable {
    let multiTouchTopicID: Int
    let templateOneBody: String
    let templateTwoBody: String
    let mergeVars: [String: String]
    let touchDuration: Int

    enum CodingKeys: String, CodingKey {
        case multiTouchTopicID = "multi_touch_topic_id"
        case templateOneBody = "template_one_body"
        case templateTwoBody = "template_two_body"
        case mergeVars = "merge_vars"
        case touchDuration = "touch_two_weeks"
    }
}
// MARK: - OutgoingRadiusMailingListWrapper
struct OutgoingRadiusMailingListWrapper: Codable {
    let multiTouchTopic: OutgoingRadiusMailingListData

    enum CodingKeys: String, CodingKey {
        case multiTouchTopic = "multi_touch_topic"
    }
}
// MARK: - OutgoingRadiusMailingListData
struct OutgoingRadiusMailingListData: Codable {
    let touchTwoWeeks: Int

    enum CodingKeys: String, CodingKey {
        case touchTwoWeeks = "touch_two_weeks"
    }
}

// MARK: - OutgoingRadiusMailing
struct OutgoingRadiusMailing: Codable {
    let layoutTemplateID: Int?
    let multiTouchTopicID: Int?
    let templateOneBody: String?
    let templateTwoBody: String?
    let mergeVars: [String: String]?
    let touchDuration: Int?
    let touchDurationConfirmation: Int?

    enum CodingKeys: String, CodingKey {
        case layoutTemplateID = "layout_template_id"
        case multiTouchTopicID = "multi_touch_topic_id"
        case templateOneBody = "template_one_body"
        case templateTwoBody = "template_two_body"
        case mergeVars = "merge_vars"
        case touchDuration = "touch_duration"
        case touchDurationConfirmation = "touch_duration_confirmation"
    }
}

// MARK: - Account
struct Account: Codable {
    let id: Int

    enum CodingKeys: String, CodingKey {
        case id
    }
}

// MARK: - User
struct User: Codable {
    let id: Int

    enum CodingKeys: String, CodingKey {
        case id
    }
}

// MARK: - LayoutTemplate
struct LayoutTemplate: Codable {
    let id: Int

    enum CodingKeys: String, CodingKey {
        case id
    }
}

// MARK: - SubjectListEntry
struct SubjectListEntry: Codable, Identifiable {
    let id: Int
    let firstName: String?
    let lastName: String?
    let siteAddressLine1, siteAddressLine2: String
    let siteCity: String
    let siteState: String
    let siteZipcode: String
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case siteAddressLine1 = "site_address_line_1"
        case siteAddressLine2 = "site_address_line_2"
        case siteCity = "site_city"
        case siteState = "site_state"
        case siteZipcode = "site_zipcode"
        case status
    }
}
// MARK: - OutgoingSubjectListEntryWrapper
struct OutgoingSubjectListEntryWrapper: Codable {
    let subjectListEntry: OutgoingSubjectListEntry

    enum CodingKeys: String, CodingKey {
        case subjectListEntry = "subject_list_entry"
    }
}

// MARK: - OutgoingSubjectListEntry
struct OutgoingSubjectListEntry: Codable {
    let siteAddressLine1, siteAddressLine2, siteCity, siteState: String
    let siteZipcode, latitude, longitude, status: String

    enum CodingKeys: String, CodingKey {
        case siteAddressLine1 = "site_address_line_1"
        case siteAddressLine2 = "site_address_line_2"
        case siteCity = "site_city"
        case siteState = "site_state"
        case siteZipcode = "site_zipcode"
        case latitude, longitude, status
    }
}

// MARK: - OutgoingCustomNoteResponse
struct OutgoingCustomNoteResponse: Codable {
    let customNote: CustomNote
    let id: Int
    let status: String

    enum CodingKeys: String, CodingKey {
        case customNote = "custom_note"
        case id, status
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
struct CustomNote: Codable {
    let id: Int
    let body: String?
    let toFirstName, toLastName, toBusinessName: String
    let toToLine, toAttnLine: String?
    let toAddressLine1, toAddressLine2, toCity, toState: String
    let toZipcode, fromFirstName, fromLastName, fromBusinessName: String
    let fromToLine, fromAttnLine: String?
    let fromAddressLine1, fromAddressLine2, fromCity, fromState: String
    let fromZipcode: String
    let handwritingID: Int?
    let status: String
    let cardType, format: String?
    let mediaSize, messageTemplateID: Int?
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
        var setAsCardLayout: Bool

        init(withURL url: String, size: CGFloat, cornerRadius: CGFloat, setAsCardLayout: Bool = false) {
            imageLoader = ImageLoader(urlString: url)
            self.size = size
            self.cornerRadius = !setAsCardLayout ? cornerRadius : 0
            self.setAsCardLayout = setAsCardLayout
        }

        var body: some View {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: getImageWidth(), height: size)
                .cornerRadius(cornerRadius)
                .onReceive(imageLoader.didChange) { data in
                    self.image = UIImage(data: data) ?? UIImage(systemName: "exclamationmark.triangle")!
                }
        }

        private func getImageWidth() -> CGFloat {
            return !setAsCardLayout ? size : size * 2
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

// MARK: - MessageTemplate
struct MessageTemplate: Codable, Identifiable {
    let id: Int
    let title, body: String
    let mergeVars: [String: String]
    let owned: Bool?

    enum CodingKeys: String, CodingKey {
        case id, title, body
        case mergeVars = "merge_vars"
        case owned
    }
}

// MARK: - MultiTouchTopicResponse
struct MultiTouchTopicResponse: Codable {
    let multiTouchTopics: [MultiTouchTopicWrapper]

    enum CodingKeys: String, CodingKey {
        case multiTouchTopics = "multi_touch_topics"
    }
}

// MARK: - MultiTouchTopicWrapper
struct MultiTouchTopicWrapper: Codable {
    let multiTouchTopic: MultiTouchTopic

    enum CodingKeys: String, CodingKey {
        case multiTouchTopic = "multi_touch_topic"
    }
}

// MARK: - MultiTouchTopic
struct MultiTouchTopic: Codable, Identifiable {
    let id: Int
    let name: String
    let touchOneTemplateID: Int
    let touchTwoTemplateID: Int
    let touchDuration: Int

    enum CodingKeys: String, CodingKey {
        case id, name
        case touchOneTemplateID = "touch_one_template_id"
        case touchTwoTemplateID = "touch_two_template_id"
        case touchDuration = "touch_two_weeks"
    }
}
// MARK: - OutgoingRecipientStatus
struct OutgoingRecipientStatus: Codable {
    let status: String

    enum CodingKeys: String, CodingKey {
        case status
    }
}

struct ListEntryResponse: Codable {
    let message: String

    enum CodingKeys: String, CodingKey {
        case message
    }
}
