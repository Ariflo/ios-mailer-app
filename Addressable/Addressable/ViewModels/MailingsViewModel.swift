//
//  MailingsViewModel.swift
//  Addressable
//
//  Created by Ari on 12/29/20.
//

import SwiftUI
import Combine

class MailingsViewModel: ObservableObject, Identifiable {
    @Published var dataSource: [AddressableMailing] = []

    private let addressableDataFetcher: FetchableData
    private var disposables = Set<AnyCancellable>()

    init(addressableDataFetcher: FetchableData) {
        self.addressableDataFetcher = addressableDataFetcher
    }

    func getMailings() {
        addressableDataFetcher.getCurrentUserMailings()
            .map { resp in
                resp.mailings.map { $0.mailing }
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getMailings() receiveCompletion error: \(error)")
                        self.dataSource = []
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] mailingsListData in
                    guard let self = self else { return }
                    self.dataSource = mailingsListData
                })
            .store(in: &disposables)
    }
}
