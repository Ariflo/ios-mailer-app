//
//  MessagesViewModel.swift
//  Addressable
//
//  Created by Ari on 1/14/21.
//

import SwiftUI
import Combine

enum SocketReponseTypes: String, Codable {
    case confirm = "confirm_subscription"
    case ping
    case welcome
}

class MessagesViewModel: ObservableObject {
    @Published var incomingLeadsWithMessages: IncomingLeadsResponse = []
    @Published var messages: [Message] = []
    @Published var loading: Bool = false

    private let apiService: ApiService
    private var disposables = Set<AnyCancellable>()

    var messageSid: String = ""

    init(provider: DependencyProviding) {
        self.apiService = provider.register(provider: provider)
    }

    func getIncomingLeadsWithMessages() {
        loading = true
        apiService.getIncomingLeadsWithMessages()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] value in
                    guard let self = self else { return }
                    switch value {
                    case .failure(let error):
                        print("getIncomingLeadsWithMessages() receiveCompletion error: \(error)")
                        self.incomingLeadsWithMessages = []
                        self.loading = false
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] incomingLeads in
                    guard let self = self else { return }
                    self.incomingLeadsWithMessages = incomingLeads
                    self.loading = false
                })
            .store(in: &disposables)
    }

    func getMessages(for leadId: Int) {
        apiService.getLeadMessages(for: leadId)
            .map { $0.leadMessages
                .compactMap { msg -> Message? in
                    do {
                        if let msgData = msg.data(using: .utf8) {
                            return try JSONDecoder().decode(Message.self, from: msgData)
                        } else {
                            return nil
                        }
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
                    self.messageSid = !messages.isEmpty ? messages[0].messageSid : ""
                })
            .store(in: &disposables)
    }

    func sendMessage(_ message: OutgoingMessage) {
        guard let encodedMessage = try? JSONEncoder().encode(OutgoingMessageWrapper(outgoingMessage: message)) else {
            print("Message Encoding Error")
            return
        }
        apiService.sendLeadMessage(encodedMessage)
            .map { $0.leadMessages
                .compactMap { msg -> Message? in
                    do {
                        if let msgData = msg.data(using: .utf8) {
                            return try JSONDecoder().decode(Message.self, from: msgData)
                        } else {
                            return nil
                        }
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
    // swiftlint:disable cyclomatic_complexity
    func connectToSocket() {
        if let userToken = KeyChainServiceUtil.shared[userAppToken] {
            apiService.connectToWebSocket(userToken: userToken) {[weak self] data in
                guard let self = self else { return }
                guard data != nil else {
                    print("No data to confirm connection to socket")
                    return
                }
                // Subscribe to latest leads messages
                self.apiService.subscribe(command: "subscribe", identifier: "{\"channel\": \"LeadMessagesChannel\"}")
                // swiftlint:disable force_unwrapping
                guard let socketResponseData = try? JSONDecoder()
                        .decode(MessageSubscribeResponse.self, from: data!)
                else {
                    // Log Socket Pings
                    #if DEBUG
                    do {
                        let socketPingResponseData = try JSONDecoder()
                            .decode(
                                MessageSubscribePingResponse.self,
                                from: data!
                            )

                        switch socketPingResponseData.type {
                        case .confirm:
                            print("User Successfully Subscribed -> socketResponseData: \(socketPingResponseData)")
                        case .ping:
                            print("Socket Ping -> socketResponseData: \(socketPingResponseData)")
                        case .welcome:
                            print("User Successfully Connected to Socket -> " +
                                    "socketResponseData: \(socketPingResponseData)")
                        case .none:
                            print("Unknown -> socketResponseData: \(socketPingResponseData)")
                        }
                    } catch {
                        print("connectToSocket MessageSubscribeResponse decoding error: \(error)")
                    }
                    #endif
                    return
                }
                if let socketMessageData = socketResponseData.message {
                    DispatchQueue.main.async {
                        self.messages = socketMessageData.leadMessages.compactMap { msg -> Message? in
                            do {
                                if let msgData = msg.data(using: .utf8) {
                                    return try JSONDecoder().decode(Message.self, from: msgData)
                                } else {
                                    return nil
                                }
                            } catch {
                                print("JSON decoding error: \(error)")
                                return nil
                            }
                        }
                    }
                }
            }
        }
    }

    func disconnectFromSocket() {
        apiService.disconnectFromWebSocket()
    }
}
