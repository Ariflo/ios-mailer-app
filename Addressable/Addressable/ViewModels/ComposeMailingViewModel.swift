//
//  ComposeMailingViewModel.swift
//  Addressable
//
//  Created by Ari on 1/26/21.
//

import SwiftUI
import Combine

class ComposeMailingViewModel: ObservableObject, Identifiable {
    private let addressableDataFetcher: FetchableData
    private var disposables = Set<AnyCancellable>()

    @Published var step = ComposeMailingSteps.toForm
    @Published var toFirstName: String = ""
    @Published var toLastName: String = ""
    @Published var toBusinessName: String = ""
    @Published var toAddressLine1: String = ""
    @Published var toAddressLine2: String = ""
    @Published var toCity: String = ""
    @Published var toState: String = ""
    @Published var toZipcode: String = ""

    @Published var fromFirstName: String = ""
    @Published var fromLastName: String = ""
    @Published var fromBusinessName: String = ""
    @Published var fromAddressLine1: String = ""
    @Published var fromAddressLine2: String = ""
    @Published var fromCity: String = ""
    @Published var fromState: String = ""
    @Published var fromZipcode: String = ""

    @Published var body: String = "Write your message here..."
    @Published var selectedCoverArtID: Int?
    @Published var selectedMessageTemplateID: Int?

    @Published var mailingArt: [MailingCoverArt] = []
    @Published var messageTemplates: [MessageTemplate] = []
    @Published var customNote: OutgoingCustomNote?

    init(addressableDataFetcher: FetchableData) {
        self.addressableDataFetcher = addressableDataFetcher
    }

    func updateCustomNote() {
        customNote = OutgoingCustomNote(
            toFirstName: toFirstName,
            toLastName: toLastName,
            toBusinessName: toBusinessName.isEmpty ? nil : toBusinessName,
            toAddressLine1: toAddressLine1,
            toAddressLine2: toAddressLine2.isEmpty ? nil : toAddressLine2,
            toCity: toCity,
            toState: toState,
            toZipcode: toZipcode,
            body: body,
            selectedCoverArtID: selectedCoverArtID,
            selectedMessageTemplateID: selectedMessageTemplateID,
            fromFirstName: fromFirstName,
            fromLastName: fromLastName,
            fromBusinessName: fromBusinessName.isEmpty ? nil : fromBusinessName,
            fromAddressLine1: fromAddressLine1,
            fromAddressLine2: fromAddressLine2.isEmpty ? nil : fromAddressLine2,
            fromCity: fromCity,
            fromState: fromState,
            fromZipcode: fromZipcode,
            cardType: "logo"
        )
    }

    func sendMailing(completion: @escaping (String?) -> Void) {
        guard let encodedMailing = try? JSONEncoder().encode(OutGoingCustomNoteWrapper(customNote: customNote!)) else {
            print("Custom Note Encoding Error")
            return
        }
        addressableDataFetcher.sendCustomMailing(encodedMailing)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("sendCustomMailing() receiveCompletion error: \(error)")
                        completion(nil)
                    case .finished:
                        break
                    }
                },
                receiveValue: {mailingSent in
                    completion(mailingSent.status)
                })
            .store(in: &disposables)
    }

    func getMailingCoverArtOptions() {
        addressableDataFetcher.getMailingCoverArt()
            .map { resp in
                resp.mailingCoverArts.map { $0.mailingCoverArt }
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getMailingArtOptions() receiveCompletion error: \(error)")
                        self.mailingArt = []
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] mailingArtOptions in
                    guard let self = self else { return }
                    self.mailingArt = mailingArtOptions
                })
            .store(in: &disposables)
    }

    func getMailingReturnAddress() {
        addressableDataFetcher.getMailingReturnAddress()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getMailingReturnAddress() receiveCompletion error: \(error)")
                        self.fromFirstName = ""
                        self.fromLastName = ""
                        self.fromBusinessName = ""
                        self.fromAddressLine1 = ""
                        self.fromAddressLine2 = ""
                        self.fromCity = ""
                        self.fromState = ""
                        self.fromZipcode = ""
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] mailingReturnAddress in
                    guard let self = self else { return }
                    self.fromFirstName = mailingReturnAddress.firstName
                    self.fromLastName = mailingReturnAddress.lastName
                    self.fromBusinessName = mailingReturnAddress.companyName
                    self.fromAddressLine1 = mailingReturnAddress.addressLine1
                    self.fromAddressLine2 = mailingReturnAddress.addressLine2
                    self.fromCity = mailingReturnAddress.city
                    self.fromState = mailingReturnAddress.state
                    self.fromZipcode = mailingReturnAddress.zipcode
                })
            .store(in: &disposables)
    }

    func getMessageTemplates() {
        addressableDataFetcher.getMessageTemplates()
            .map { resp in
                resp.messageTemplates.map { $0.messageTemplate }
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getMessageTemplates() receiveCompletion error: \(error)")
                        self.messageTemplates = []
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] templates in
                    guard let self = self else { return }
                    self.messageTemplates = templates
                })
            .store(in: &disposables)
    }
}
