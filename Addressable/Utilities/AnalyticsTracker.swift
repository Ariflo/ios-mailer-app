//
//  AnalyticsTracker.swift
//  Addressable
//
//  Created by Ari on 8/18/21.
//

import Foundation
import CoreData

enum AnalyticsEvent: String {
    case mobileLoginSuccess = "mobile_login_success"
    case mobileLoginFailed = "mobile_login_failed"
    case mobileLogoutSuccess = "mobile_logout_success"
    case mobileAppBackgrounded = "mobile_app_backgrounded"
    case mobileAppOpened = "mobile_app_opened"
    case mobileAppInstalled = "mobile_app_installed"
    case mobileAppUpdated = "mobile_app_updated"
    case pushNotificationPressed = "mobile_app_push_notification_pressed"
    case pushNotificationRecieved = "mobile_app_push_notification_recieved"
    case mobileAppCrashed = "mobile_app_crashed"
}

class AnalyticsTracker {
    init(provider: DependencyProviding) {}

    func trackEvent(_ eventName: AnalyticsEvent, context: NSManagedObjectContext) {
        AnalyticEvent.createWith(eventType: eventName.rawValue, using: context)
    }
}
