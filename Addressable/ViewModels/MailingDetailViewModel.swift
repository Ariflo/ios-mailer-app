//
//  MailingDetailViewModel.swift
//  Addressable
//
//  Created by Ari on 6/7/21.
//

import SwiftUI
import Combine

class MailingDetailViewModel: ObservableObject {
    private let apiService: ApiService
    let analyticsTracker: AnalyticsTracker
    private var disposables = Set<AnyCancellable>()

    @Published var mailing: Mailing

    @Published var selectedFrontImageData: Data?
    @Published var selectedBackImageData: Data?
    @Published var selectedImageId: Int = 0
    @Published var numActiveRecipients: Int = 0

    init(provider: DependencyProviding, selectedMailing: Mailing) {
        apiService = provider.register(provider: provider)
        analyticsTracker = provider.register(provider: provider)
        mailing = selectedMailing

        if let layoutTemplateId = selectedMailing.layoutTemplate?.id {
            selectedImageId = layoutTemplateId
        }
    }

    func cancelMailing(completion: @escaping (Mailing?) -> Void) {
        guard let createTransactionData = try? JSONEncoder().encode(
            CreateMailingTransaction(
                customNote: nil,
                approveForPrint: ApproveForPrint(
                    finalQuantity: mailing.activeRecipientCount,
                    status: "draft"
                )
            )
        ) else {
            print("Encoding Error in cancelMailing()")
            return
        }

        apiService.createTransaction(accountId: mailing.account.id, mailingId: mailing.id, transactionData: createTransactionData)
            .map { $0.mailing }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("createTransaction() in cancelMailing() receiveCompletion error: \(error)")
                        completion(nil)
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] completeTransactionMailing in
                    guard let self = self else { return }
                    self.mailing = completeTransactionMailing
                    completion(completeTransactionMailing)
                })
            .store(in: &disposables)
    }
}
