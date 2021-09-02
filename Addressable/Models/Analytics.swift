//
//  Analytics.swift
//  Addressable
//
//  Created by Ari on 8/24/21.
//

import Foundation

// MARK: - AddressableAnalyticEvent
struct AddressableAnalyticEvent: Codable {
    let sessionId: UUID
    let eventType: String
    let eventTime: Int
    let environment: String
    let source: String
    let message: String?
    let userId: Int
    let mobileDeviceType: String
    let mobileDeviceOS: String

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case eventType = "event_type"
        case eventTime = "event_time"
        case environment
        case source
        case message
        case userId = "user_id"
        case mobileDeviceType = "mobile_device_type"
        case mobileDeviceOS = "mobile_device_os"
    }
}
