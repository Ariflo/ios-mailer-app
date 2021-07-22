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

    init(provider: DependencyProviding) {
        apiService = provider.register(provider: provider)
    }

    func getRadiusMailing(with id: Int, completion: @escaping (Mailing?) -> Void) {
        apiService.getSelectedRadiusMailing(for: id)
            .map { $0.radiusMailing }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        completion(nil)
                        print("getRadiusMailing(for id: \(id)), receiveCompletion error: \(error)")
                    case .finished:
                        break
                    }
                },
                receiveValue: {radiusMailing in
                    completion(radiusMailing)
                })
            .store(in: &disposables)
    }
}
