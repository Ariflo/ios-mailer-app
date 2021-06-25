//
//  MailingRecipientsListViewModel.swift
//  Addressable
//
//  Created by Ari on 6/9/21.
//

import SwiftUI
import Combine


class MailingRecipientsListViewModel: ObservableObject {
    private let apiService: ApiService
    private var disposables = Set<AnyCancellable>()
    var mailing: Mailing

    @Published var recipients: [Recipient] = []
    @Published var loadingRecipients: Bool = true

    init(provider: DependencyProviding, selectedMailing: Mailing) {
        apiService = provider.register(provider: provider)
        mailing = selectedMailing
    }

    func updateListEntry(
        with listEntryId: Int,
        with listMembership: String
    ) {
        guard let encodedUpdateListEntryData = try? JSONEncoder().encode(
            OutgoingRecipientStatus(listMembership: listMembership)
        ) else {
            print("Update List Entry Encoding Error")
            return
        }

        apiService.updateRadiusListEntry(for: listEntryId, encodedUpdateListEntryData)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("updateListEntry(" +
                                "with listEntryId: \(listEntryId), " +
                                "with listMembership: \(listMembership), receiveCompletion error: \(error)")
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] _ in
                    guard let self = self else { return }
                    // Update list of recipients
                    self.getMailingRecipients()
                })
            .store(in: &disposables)
    }

    func getMailingRecipients() {
        loadingRecipients = true
        apiService.getMailingRecipients(for: mailing.id)
            .map { $0.recipients }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        self.loadingRecipients = false
                        print("getMailingRecipients() " +
                                "receiveCompletion error \(error) ")
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] recipients in
                    guard let self = self else { return }
                    self.recipients = recipients
                    self.loadingRecipients = false
                })
            .store(in: &disposables)
    }

    func removeListEntry(
        with listEntryId: Int
    ) {
        apiService.addRecipientToRemovalList(accountId: mailing.account.id, recipientId: listEntryId)
            .map {
                $0.listEntry
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("removeListEntry(" +
                                "with listEntryId: \(listEntryId), " +
                                "receiveCompletion error: \(error)"
                        )
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] _ in
                    guard let self = self else { return }
                    // Update list of recipients
                    self.loadingRecipients = true
                    // HACK: Give server time to update list
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        self.getMailingRecipients()
                    }
                })
            .store(in: &disposables)
    }
}
