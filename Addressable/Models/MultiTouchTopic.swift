//
//  MultiTouchTopic.swift
//  Addressable
//
//  Created by Ari on 5/20/21.
//

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
