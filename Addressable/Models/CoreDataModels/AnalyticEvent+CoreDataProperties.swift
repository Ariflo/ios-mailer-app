//
//  AnalyticEvent+CoreDataProperties.swift
//  Addressable
//
//  Created by Ari on 8/24/21.
//
//

import Foundation
import CoreData
import UIKit


extension AnalyticEvent {
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<AnalyticEvent> {
        return NSFetchRequest<AnalyticEvent>(entityName: "AnalyticEvent")
    }

    @NSManaged public var sessionID: UUID
    @NSManaged public var eventType: String
    @NSManaged public var eventTime: Double
    @NSManaged public var environment: String
    @NSManaged public var source: String
    @NSManaged public var message: String?
    @NSManaged public var userID: String?
    @NSManaged public var mobileDeviceType: String
    @NSManaged public var mobileDeviceOS: String

    static func createWith(
        eventType: String,
        message: String? = nil,
        using context: NSManagedObjectContext
    ) {
        guard let allPreviousEvents: [AnalyticEvent] = try? context.fetch(self.fetchRequest()) else {
            print("allPreviousEvents fetch error")
            return
        }

        guard let keyStoreUser = KeyChainServiceUtil.shared[userData],
              let userData = keyStoreUser.data(using: .utf8),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            print("keystore user fetch error")
            return
        }

        let event = AnalyticEvent(context: context)

        event.eventType = eventType
        event.eventTime = Date().timeIntervalSince1970
        event.sessionID = getEventSessionID(for: event, from: allPreviousEvents)
        event.environment = Bundle.main.object(forInfoDictionaryKey: "ANALYTICS_ENV") as? String ?? "development"
        event.source = "mobile"
        event.message = message
        event.userID = String(user.id)
        event.mobileDeviceType = "\(UIDevice.current.modelName)"
        event.mobileDeviceOS = "\(UIDevice.current.systemName) - \(UIDevice.current.systemVersion)"

        #if DEBUG || STAGING
        print("*** EVENT_ADDED *** \(event.eventType) - \(event.sessionID)")
        print("*** EVENT_DEVICE *** \(UIDevice.current.modelName)")
        print("*** EVENT_ENV *** \(event.environment)")
        print("*** EVENT_DEVICE_OS *** \(UIDevice.current.systemName) - \(UIDevice.current.systemVersion)")
        #endif

        do {
            try context.save()
            guard let allCurrentAnalyticsEvents: [AnalyticEvent] = try? context.fetch(self.fetchRequest()) else {
                print("allCurrentAnalyticsEvents Fetch Error")
                return
            }
            #if DEBUG || STAGING
            print("*** EVENTS_COUNT ***\(allCurrentAnalyticsEvents.count)")
            print("*** 10_MIN_PASSED ***\(timePassedSinceLastEvent(in: allCurrentAnalyticsEvents, min: 10))")
            #endif
            if allCurrentAnalyticsEvents.count >= 10 ||
                timePassedSinceLastEvent(in: allCurrentAnalyticsEvents, min: 10) {
                self.flush(with: context)
            }
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    private static func getEventSessionID(
        for newEvent: AnalyticEvent,
        from allEvents: [AnalyticEvent]
    ) -> UUID {
        if let lastEvent = allEvents.isEmpty ? lastEventPostFlush : allEvents.last {
            let isLoginAfterInstall = lastEvent.eventType == AnalyticsEvent.mobileAppInstalled.rawValue &&
                newEvent.eventType == AnalyticsEvent.mobileLoginSuccess.rawValue

            if !timePassedSinceLastEvent(in: [lastEvent, newEvent], min: 30) &&
                (isLoginAfterInstall || newEvent.eventType != AnalyticsEvent.mobileLoginSuccess.rawValue) {
                return lastEvent.sessionID
            }
        }
        return UUID()
    }

    private static func timePassedSinceLastEvent(in allEvents: [AnalyticEvent], min: Int) -> Bool {
        let lastTwoEvents = Array(allEvents.sorted { $0.eventTime < $1.eventTime }.suffix(2))
        if lastTwoEvents.count == 2 {
            return Date(timeIntervalSince1970: lastTwoEvents[1].eventTime)
                .minutes(from: Date(timeIntervalSince1970: lastTwoEvents[0].eventTime)) >= min
        }
        return false
    }

    private static func flush(with context: NSManagedObjectContext) {
        guard let sendAnalyticsUrl = URL(
            string: "https://r92a9uxeh3.execute-api.us-west-1.amazonaws.com/Prod/mobile"
        ) else {
            print("sendAnalyticsUrl Encoding Error")
            return
        }

        var request = URLRequest(url: sendAnalyticsUrl)

        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Xa2i&32-dc94-2!sabbis12994", forHTTPHeaderField: "x-api-key")

        guard let allAnalyticsEvents: [AnalyticEvent] = try? context.fetch(self.fetchRequest()) else {
            print("allAnalyticsEvents Fetch Error")
            return
        }
        // swiftlint:disable force_unwrapping
        guard let encodedAddressableAnalyticsEvents = try? JSONEncoder().encode(
            allAnalyticsEvents.map { event in
                AddressableAnalyticEvent(
                    sessionId: event.sessionID,
                    eventType: event.eventType,
                    eventTime: Int(event.eventTime),
                    environment: event.environment,
                    source: event.source,
                    message: nil,
                    userId: event.userID != nil ? Int(event.userID!)! : -1,
                    mobileDeviceType: event.mobileDeviceType,
                    mobileDeviceOS: event.mobileDeviceOS
                )
            }
        ) else {
            print("encodedAddressableAnalyticsEvents Encoding Error")
            return
        }
        request.httpBody = encodedAddressableAnalyticsEvents
        #if DEBUG || STAGING
        print(allAnalyticsEvents.map { event in
            AddressableAnalyticEvent(
                sessionId: event.sessionID,
                eventType: event.eventType,
                eventTime: Int(event.eventTime),
                environment: event.environment,
                source: event.source,
                message: nil,
                userId: event.userID != nil ? Int(event.userID!)! : -1,
                mobileDeviceType: event.mobileDeviceType,
                mobileDeviceOS: event.mobileDeviceOS
            )
        })
        #endif

        URLSession.shared.dataTask(with: request) { _, _, error in
            guard error == nil else {
                print("****** flush() Error: \(String(describing: error)) *****")
                return
            }
            #if DEBUG || STAGING
            print("START REMOVE ALL ANALYTICS EVENTS")
            #endif
            self.lastEventPostFlush = allAnalyticsEvents.sorted { $0.eventTime < $1.eventTime }.last
            for eventObj in allAnalyticsEvents {
                let managedObjectData: NSManagedObject = eventObj
                context.delete(managedObjectData)
                #if DEBUG || STAGING
                print("EVENT REMOVED")
                #endif
            }
            #if DEBUG || STAGING
            print("ALL ANALYTICS EVENTS REMOVED")
            #endif
        }
        .resume()
    }
}
