//
//  ProfileViewModel.swift
//  Addressable
//
//  Created by Ari on 5/19/21.
//

import SwiftUI
import Combine

class ProfileViewModel: ObservableObject {
    private let addressableDataFetcher: FetchableData
    private var disposables = Set<AnyCancellable>()

    init(addressableDataFetcher: FetchableData) {
        self.addressableDataFetcher = addressableDataFetcher
    }

    func logout(onCompletion: @escaping (MobileUserLoggedOutResponse?) -> Void) {
        addressableDataFetcher.logoutMobileUser()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard self != nil else { return }
                    switch value {
                    case .failure(let error):
                        print("logout() receiveCompletion error: \(error)")
                        onCompletion(nil)
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] logoutResponse in
                    guard self != nil else { return }
                    onCompletion(logoutResponse)
                })
            .store(in: &disposables)
    }
}
