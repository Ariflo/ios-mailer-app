//
//  CallViewModel.swift
//  Addressable
//
//  Created by Ari on 1/13/21.
//

import SwiftUI
import Combine

class CallsViewModel: ObservableObject {
    private let apiService: ApiService
    private var disposables = Set<AnyCancellable>()

    @Published var loading: Bool = false
    @Published var incomingLeads: IncomingLeadsResponse = []

    @Published var refreshIncomingLeadsData: Bool = false {
        didSet {
            if oldValue == false && refreshIncomingLeadsData == true {
                getLeads()
                // When finished refreshing data (must be done on the main thread)
                self.refreshIncomingLeadsData = false
            }
        }
    }

    init(provider: DependencyProviding) {
        apiService = provider.register(provider: provider)
    }

    func getLeads() {
        loading = true
        apiService.getIncomingLeads()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getLeads() receiveCompletion error: \(error)")
                        self.incomingLeads = []
                        self.loading = false
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] incomingLeads in
                    guard let self = self else { return }
                    self.incomingLeads = incomingLeads
                    self.loading = false
                })
            .store(in: &disposables)
    }

    func addCallParticipant(addNumber: String, fromNumber: String) {
        guard let sessionID = KeyChainServiceUtil.shared[userMobileClientIdentity] else {
            print("No Session ID to Add Participant")
            return
        }
        guard let encodedCallData = try? JSONEncoder().encode(
            NewCaller(
                sessionID: sessionID,
                addNumber: addNumber,
                fromNumber: fromNumber
            )
        ) else {
            print("Add Caller Encoding Error")
            return
        }
        apiService.addCallParticipant(encodedCallData)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("addCallParticipant() receiveCompletion error: \(error)")
                    case .finished:
                        break
                    }
                },
                receiveValue: { _ in })
            .store(in: &disposables)
    }
}
