//
//  CallViewModel.swift
//  Addressable
//
//  Created by Ari on 1/13/21.
//

import SwiftUI
import Combine

class CallsViewModel: ObservableObject, Identifiable {
    @Published var dataSource: IncomingLeadsResponse = []
    private let addressableDataFetcher: FetchableData
    private var disposables = Set<AnyCancellable>()

    init(addressableDataFetcher: FetchableData) {
        self.addressableDataFetcher = addressableDataFetcher
    }

    func getLeads() {
        addressableDataFetcher.getIncomingLeads()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure:
                        self.dataSource = []
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] incomingLeads in
                    print(incomingLeads)
                    guard let self = self else { return }
                    self.dataSource = incomingLeads
                })
            .store(in: &disposables)
    }
}
