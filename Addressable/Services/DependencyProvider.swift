//
//  DependencyProvider.swift
//  Addressable
//
//  Created by Ari on 5/20/21.
//

import Foundation

protocol DependencyProviding: ServiceProviding, UtilityProviding {}

class DependencyProvider: DependencyProviding {
    private let serviceProvider = ServiceProvider()
    private let utilityProvider = UtilityProvider()

    func register<SERVICE: Service>(provider: DependencyProviding) -> SERVICE {
        return serviceProvider.register(provider: provider)
    }

    func register(provider: DependencyProviding) -> AnalyticsTracker {
        return utilityProvider.register(provider: provider)
    }
}
