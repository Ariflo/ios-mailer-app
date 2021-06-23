//
//  DependencyProvider.swift
//  Addressable
//
//  Created by Ari on 5/20/21.
//

import Foundation

protocol DependencyProviding: ServiceProviding {}

class DependencyProvider: DependencyProviding {
    private let serviceProvider = ServiceProvider()

    func register<SERVICE: Service>(provider: DependencyProviding) -> SERVICE {
        return serviceProvider.register(provider: provider)
    }
}
