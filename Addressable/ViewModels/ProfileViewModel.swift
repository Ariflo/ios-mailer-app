//
//  ProfileViewModel.swift
//  Addressable
//
//  Created by Ari on 5/19/21.
//

import SwiftUI
import Combine

class ProfileViewModel: ObservableObject {
    private let apiService: ApiService
    private var disposables = Set<AnyCancellable>()

    init(provider: DependencyProviding) {
        self.apiService = provider.register(provider: provider)
    }

    func logout(onCompletion: @escaping (MobileUserLoggedOutResponse?) -> Void) {
        apiService.logoutMobileUser()
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
