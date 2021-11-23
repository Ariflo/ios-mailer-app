//
//  MailingsViewModel.swift
//  Addressable
//
//  Created by Ari on 12/29/20.
//

import SwiftUI
import Combine

class DashboardViewModel: ObservableObject {
    @Published var loading: Bool = false

    private let apiService: ApiService
    private var disposables = Set<AnyCancellable>()
    let analyticsTracker: AnalyticsTracker

    init(provider: DependencyProviding) {
        apiService = provider.register(provider: provider)
        analyticsTracker = provider.register(provider: provider)
    }

    func getMailing(with id: Int, completion: @escaping (Mailing?) -> Void) {
        apiService.getSelectedMailing(for: id)
            .map { $0.mailing }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        completion(nil)
                        print("getMailing(for id: \(id)), receiveCompletion error: \(error)")
                    case .finished:
                        break
                    }
                },
                receiveValue: { mailing in
                    completion(mailing)
                })
            .store(in: &disposables)
    }

    func verifyMobileRegistration(with deviceId: String, completion: @escaping (MobileIdentityResponse?) -> Void) {
        apiService.verifyMobileIdentity(with: deviceId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        completion(nil)
                        print("verifyMobileRegistration(), receiveCompletion error: \(error)")
                    case .finished:
                        break
                    }
                },
                receiveValue: { mobileIdentityResponse in
                    completion(mobileIdentityResponse)
                })
            .store(in: &disposables)
    }
}
