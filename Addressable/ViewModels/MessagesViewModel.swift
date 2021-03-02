//
//  MessagesViewModel.swift
//  Addressable
//
//  Created by Ari on 1/14/21.
//

import SwiftUI
import Combine

class MessagesViewModel: ObservableObject, Identifiable {
    @Published var incomingLeadsWithMessages: IncomingLeadsResponse = []
    @Published var messages: [Message] = []

    private let addressableDataFetcher: FetchableData
    private var disposables = Set<AnyCancellable>()

    var messageSid: String = ""

    init(addressableDataFetcher: FetchableData) {
        self.addressableDataFetcher = addressableDataFetcher
    }

    func getIncomingLeadsWithMessages() {
        addressableDataFetcher.getIncomingLeadsWithMessages()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getIncomingLeadsWithMessages() receiveCompletion error: \(error)")
                        self.incomingLeadsWithMessages = []
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] incomingLeads in
                    guard let self = self else { return }
                    self.incomingLeadsWithMessages = incomingLeads
                })
            .store(in: &disposables)
    }

    func getMessages(for leadId: Int) {
        addressableDataFetcher.getLeadMessages(for: leadId)
            .map { $0.leadMessages
                .compactMap { msg -> Message? in
                    do {
                        return try JSONDecoder().decode(Message.self, from: msg.data(using: .utf8)!)
                    } catch {
                        print("getMessages(for leadID: \(leadId)) JSON decoding error: \(error)")
                        return nil
                    }
                }
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getMessages() receiveCompletion error: \(error)")
                        self.messages = []
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] messages in
                    guard let self = self else { return }
                    self.messages = messages
                    self.messageSid = messages.count > 0 ? messages[0].messageSid : ""
                })
            .store(in: &disposables)
    }

    func sendMessage(_ message: OutgoingMessage) {
        guard let encodedMessage = try? JSONEncoder().encode(OutgoingMessageWrapper(outgoingMessage: message)) else {
            print("Message Encoding Error")
            return
        }
        addressableDataFetcher.sendLeadMessage(encodedMessage)
            .map { $0.leadMessages
                .compactMap { msg -> Message? in
                    do {
                        return try JSONDecoder().decode(Message.self, from: msg.data(using: .utf8)!)
                    } catch {
                        print("getMessages(_ message: \(message)) JSON decoding error: \(error)")
                        return nil
                    }
                }
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("sendMessage() receiveCompletion error: \(error)")
                        self.messages = []
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] messages in
                    guard let self = self else { return }
                    self.messages = messages
                })
            .store(in: &disposables)
    }
}
