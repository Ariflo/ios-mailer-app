//
//  ConfirmAndSendMailingViewModel.swift
//  Addressable
//
//  Created by Ari on 7/27/21.
//

import SwiftUI
import Combine

class ConfirmAndSendMailingViewModel: ObservableObject {
    @Published var isEditingTargetDropDate: Bool = false

    private let apiService: ApiService
    private var disposables = Set<AnyCancellable>()

    @Binding var mailing: Mailing
    var selectedDropDate: String = ""

    init(provider: DependencyProviding, selectedMailing: Binding<Mailing>) {
        apiService = provider.register(provider: provider)
        _mailing = selectedMailing
    }

    func setSelectedDropDate(selectedDate: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        selectedDropDate = dateFormatter.string(from: selectedDate)
    }

    func sendMailing(completion: @escaping (Mailing?) -> Void) {
        guard let createTransactionData = try? JSONEncoder().encode(
            SendMailing(
                mailing: TargetDropDate(
                    tagetDropDate: selectedDropDate
                ),
                approveForPrint: ApproveForPrint(
                    finalQuantity: mailing.activeRecipientCount,
                    status: "production_ready"
                )
            )
        ) else {
            print("Encoding Error in sendMailing()")
            return
        }

        apiService.createTransaction(accountId: mailing.account.id, mailingId: mailing.id, transactionData: createTransactionData)
            .map { $0.mailing }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("sendMailing() receiveCompletion error: \(error)")
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
