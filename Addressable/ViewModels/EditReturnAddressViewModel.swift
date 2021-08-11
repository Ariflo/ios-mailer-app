//
//  EditReturnAddressViewModel.swift
//  Addressable
//
//  Created by Ari on 6/17/21.
//

import SwiftUI
import Combine


class EditReturnAddressViewModel: ObservableObject {
    private let apiService: ApiService
    private var disposables = Set<AnyCancellable>()

    @Binding var mailing: Mailing

    @Published var fromFirstName: String = ""
    @Published var fromLastName: String = ""
    @Published var fromBusinessName: String = ""
    @Published var fromAddressLine1: String = ""
    @Published var fromAddressLine2: String = ""
    @Published var fromCity: String = ""
    @Published var fromState: String = ""
    @Published var fromZipcode: String = ""

    init(provider: DependencyProviding, selectedMailing: Binding<Mailing>) {
        apiService = provider.register(provider: provider)
        _mailing = selectedMailing
    }

    func updateMailingReturnAddress(completionHandler: @escaping (Mailing?) -> Void) {
        guard let updateReturnAddressData = try? JSONEncoder().encode(
            OutgoingMailingFromAddress(customNote: ReturnAddress(
                fromFirstName: fromFirstName,
                fromLastName: fromLastName,
                fromBusinessName: fromBusinessName,
                fromAddressLine1: fromAddressLine1,
                fromAddressLine2: fromAddressLine2,
                fromCity: fromCity,
                fromState: fromState,
                fromZipcode: fromZipcode
            ))
        ) else {
            print("Update Radius Mailing FROM ADDRESS Encoding Error")
            return
        }

        apiService.updateMailingReturnAddress(for: mailing.id, returnAddressData: updateReturnAddressData)
            .map { resp in resp.mailing }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("updateMailingReturnAddress(), receiveCompletion error: \(error)")
                        completionHandler(nil)
                    case .finished:
                        break
                    }
                },
                receiveValue: { mailing in
                    completionHandler(mailing)
                })
            .store(in: &disposables)
    }

    func populateFields() {
        fromFirstName = mailing.fromAddress.fromFirstName
        fromLastName = mailing.fromAddress.fromLastName
        fromBusinessName = mailing.fromAddress.fromBusinessName
        fromAddressLine1 = mailing.fromAddress.fromAddressLine1
        fromAddressLine2 = mailing.fromAddress.fromAddressLine2
        fromCity = mailing.fromAddress.fromCity
        fromState = mailing.fromAddress.fromState
        fromZipcode = mailing.fromAddress.fromZipcode
    }
}
