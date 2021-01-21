//
//  CallViewModel.swift
//  Addressable
//
//  Created by Ari on 1/13/21.
//

import SwiftUI
import Combine

class CallsViewModel: ObservableObject, Identifiable {
    @Published var incomingLeads: IncomingLeadsResponse = []
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
                    case .failure(let error):
                        print("getLeads() receiveCompletion error: \(error)")
                        self.incomingLeads = []
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] incomingLeads in
                    guard let self = self else { return }
                    self.incomingLeads = incomingLeads
                })
            .store(in: &disposables)
    }
}
