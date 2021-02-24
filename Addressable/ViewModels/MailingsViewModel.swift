//
//  MailingsViewModel.swift
//  Addressable
//
//  Created by Ari on 12/29/20.
//

import SwiftUI
import Combine

class MailingsViewModel: ObservableObject, Identifiable {
    @Published var customNotes: [CustomNote] = []
    @Published var radiusMailings: [RadiusMailing] = []
    @Published  var selectedRadiusMailing: RadiusMailing?

    private let addressableDataFetcher: FetchableData
    private var disposables = Set<AnyCancellable>()

    init(addressableDataFetcher: FetchableData) {
        self.addressableDataFetcher = addressableDataFetcher
    }

    func getAllMailingCampaigns() {
        addressableDataFetcher.getCurrentUserMailingCampaigns()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getAllMailingCampaigns() receiveCompletion error: \(error)")
                        self.customNotes = []
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] campaignsData in
                    guard let self = self else { return }
                    self.customNotes = campaignsData.campaigns.compactMap { $0.customNote }
                    self.radiusMailings = campaignsData.campaigns.compactMap { $0.radiusMailing }
                })
            .store(in: &disposables)
    }
}
