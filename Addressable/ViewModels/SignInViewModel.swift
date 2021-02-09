//
//  SignInViewModel.swift
//  Addressable
//
//  Created by Ari on 1/4/21.
//

import SwiftUI
import Combine

class SignInViewModel: ObservableObject, Identifiable {
    private let addressableDataFetcher: FetchableData
    private var disposables = Set<AnyCancellable>()

    init(addressableDataFetcher: FetchableData) {
        self.addressableDataFetcher = addressableDataFetcher
    }

    func login(with basicAuthtoken: String, onAuthenticationCompletion: @escaping (AuthorizedUserResponse?) -> Void) {
        addressableDataFetcher.getCurrentUserAuthorization(with: basicAuthtoken)
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
