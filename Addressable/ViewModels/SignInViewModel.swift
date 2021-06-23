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
    private var disposables = Set<AnyCancellable>()

    init(provider: DependencyProviding) {
        apiService = provider.register(provider: provider)
    }

    func login(with basicAuthtoken: String, onAuthenticationCompletion: @escaping (AuthorizedUserResponse?) -> Void) {
        apiService.getCurrentUserAuthorization(with: basicAuthtoken)
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
                receiveValue: { [weak self] apiData in
                    guard self != nil else { return }
                    // TODO: Consider using response status here as opposed to data returned.
                    onAuthenticationCompletion(apiData)
                })
            .store(in: &disposables)
    }
}
