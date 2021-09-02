//
//  SignInViewModel.swift
//  Addressable
//
//  Created by Ari on 1/4/21.
//

import SwiftUI
import Combine

class SignInViewModel: ObservableObject {
    private let apiService: ApiService
    let analyticsTracker: AnalyticsTracker
    private var disposables = Set<AnyCancellable>()

    init(provider: DependencyProviding) {
        apiService = provider.register(provider: provider)
        analyticsTracker = provider.register(provider: provider)
    }

    func login(with basicAuthtoken: String, onAuthenticationCompletion: @escaping (User?) -> Void) {
        apiService.getCurrentUserAuthorization(with: basicAuthtoken)
            .map { $0.user }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard self != nil else { return }
                    switch value {
                    case .failure(let error):
                        print("login() receiveCompletion error: \(error)")
                        onAuthenticationCompletion(nil)
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] authorizedUser in
                    guard self != nil else { return }
                    onAuthenticationCompletion(authorizedUser)
                })
            .store(in: &disposables)
    }
}
