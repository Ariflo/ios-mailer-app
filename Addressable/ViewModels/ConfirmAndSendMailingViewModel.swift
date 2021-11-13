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
    let analyticsTracker: AnalyticsTracker
    private var disposables = Set<AnyCancellable>()

    @Binding var mailing: Mailing
    var selectedDropDate: String = ""

    init(provider: DependencyProviding, selectedMailing: Binding<Mailing>) {
        apiService = provider.register(provider: provider)
        analyticsTracker = provider.register(provider: provider)
        _mailing = selectedMailing
        // Initialize selectedDropDate to current day + ten
        if let datePlusTen = Calendar.current.date(byAdding: .day, value: 10, to: Date()) {
            setSelectedDropDate(selectedDate: datePlusTen)
        }
    }

    func setSelectedDropDate(selectedDate: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        selectedDropDate = dateFormatter.string(from: selectedDate)
    }

    func sendMailing(completion: @escaping (MailingResponse?) -> Void) {
        guard let createTransactionData = try? JSONEncoder().encode(
            CreateMailingTransaction(
                customNote: TargetDropDate(
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
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("createTransaction() in sendMailing() receiveCompletion error: \(error)")
                        completion(nil)
                    case .finished:
                        break
                    }
                },
                receiveValue: { completeTransactionMailingResp in
                    self.mailing = completeTransactionMailingResp.mailing
                    completion(completeTransactionMailingResp)
                })
            .store(in: &disposables)
    }
}
