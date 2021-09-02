//
//  UtilityProvider.swift
//  Addressable
//
//  Created by Ari on 8/18/21.
//

import Foundation

protocol UtilityProviding {
    func register(provider: DependencyProviding) -> AnalyticsTracker
}

class UtilityProvider {
    private var instances: [String: Any] = [:]

    func register(provider: DependencyProviding) -> AnalyticsTracker {
        let key = "\(AnalyticsTracker.self)"
        guard let tracker = instances[key] as? AnalyticsTracker else {
            let tracker = AnalyticsTracker(provider: provider)
            instances[key] = tracker
            return tracker
        }
        return tracker
    }
}
