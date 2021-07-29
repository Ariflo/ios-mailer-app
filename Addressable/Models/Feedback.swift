//
//  Feedback.swift
//  Addressable
//
//  Created by Ari on 7/29/21.
//

import Foundation

// MARK: - Feedback
struct FeedbackWrapper: Codable {
    let feedback: Feedback
}

// MARK: - Feedback
struct Feedback: Codable {
    let appVersion, feedbackMessage, userToken: String

    enum CodingKeys: String, CodingKey {
        case appVersion = "app_version"
        case feedbackMessage = "feedback_message"
        case userToken = "user_token"
    }
}
