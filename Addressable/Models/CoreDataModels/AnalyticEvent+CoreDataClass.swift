//
//  AnalyticEvent+CoreDataClass.swift
//  Addressable
//
//  Created by Ari on 8/24/21.
//
//

import Foundation
import CoreData

@objc(AnalyticEvent)
public class AnalyticEvent: NSManagedObject {
    static var lastEventPostFlush: AnalyticEvent?
}
