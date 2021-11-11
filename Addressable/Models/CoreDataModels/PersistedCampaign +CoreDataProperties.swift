//
//  PersistedCampaign+CoreDataProperties.swift
//  Addressable
//
//  Created by Ari on 9/30/21.
//
//

import Foundation
import CoreData


extension PersistedCampaign {
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<PersistedCampaign> {
        return NSFetchRequest<PersistedCampaign>(entityName: "PersistedCampaign")
    }

    @NSManaged var mailing: Data

    static func createWith(
        mailingData: Data,
        using context: NSManagedObjectContext
    ) {
        let newPersistedCampaign = PersistedCampaign(context: context)
        newPersistedCampaign.mailing = mailingData

        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    static func clearAll(using context: NSManagedObjectContext) {
        guard let allCampaignMailings: [PersistedCampaign] = try? context.fetch(self.fetchRequest()) else {
            print("allCampaignMailings Fetch Error")
            return
        }

        for eventObj in allCampaignMailings {
            let managedObjectData: NSManagedObject = eventObj
            context.delete(managedObjectData)
            #if DEBUG || STAGING
            print("PERSISTED MAILING REMOVED")
            #endif
        }
    }

    static func updateStoredMailing(with mailingID: Int, mailingData: Data, using context: NSManagedObjectContext) {
        guard let allCampaignMailings: [PersistedCampaign] = try? context.fetch(self.fetchRequest()) else {
            print("allCampaignMailings Fetch Error")
            return
        }

        for campaign in allCampaignMailings where isStoredMailing(with: mailingID, campaign) {
            let managedObjectData: NSManagedObject = campaign

            context.delete(managedObjectData)
            #if DEBUG || STAGING
            print("OUTDATED PERSISTED MAILING REMOVED")
            #endif

            createWith(mailingData: mailingData, using: context)
        }
    }

    private static func isStoredMailing(with mailingID: Int, _ storedCampaign: PersistedCampaign) -> Bool {
        if let storedMailing = try? JSONDecoder().decode(Mailing.self, from: storedCampaign.mailing) {
            return storedMailing.id == mailingID
        }
        return false
    }
}
