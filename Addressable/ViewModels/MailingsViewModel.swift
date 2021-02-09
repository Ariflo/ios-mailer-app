//
//  MailingsViewModel.swift
//  Addressable
//
//  Created by Ari on 12/29/20.
//

import SwiftUI
import Combine

class MailingsViewModel: ObservableObject, Identifiable {
    @Published var mailings: [AddressableMailing] = []
    @Published var customNotes: [CustomNote] = []

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
                        self.mailings = []
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] mailingsData in
                    guard let self = self else { return }
                    self.mailings = mailingsData
                })
            .store(in: &disposables)
    }

    func getCustomNotes() {
        addressableDataFetcher.getCurrentUserCustomNotes()
            .map { resp in
                resp.customNotes.map { $0.customNote }
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getCustomNotes() receiveCompletion error: \(error)")
                        self.customNotes = []
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] customNotesData in
                    guard let self = self else { return }
                    self.customNotes = customNotesData
                })
            .store(in: &disposables)
    }
}
