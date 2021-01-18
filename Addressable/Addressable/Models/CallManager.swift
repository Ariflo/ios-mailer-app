//
//  CallManager.swift
//  Addressable
//
//  Created by Ari on 1/7/21.
//

import Foundation
import CallKit
import TwilioVoice
import Combine

class CallManager {
    var disposables = Set<AnyCancellable>()
    var callsChangedHandler: (() -> Void)?
    private let callController = CXCallController()

    private(set) var calls: [AddressableCall] = []
    // currentActiveCall represents the last connected call
    var currentActiveCall: Call?

    func callWithUUID(uuid: UUID) -> AddressableCall? {
        guard let index = calls.firstIndex(where: { $0.incomingCall?.uuid == uuid || $0.outgoingCall?.uuid == uuid }) else {
            return nil
        }
        return calls[index]
    }

    func add(_ call: AddressableCall) {
        calls.append(call)
        call.stateChanged = { [weak self] in
            guard let self = self else { return }
            self.callsChangedHandler?()
        }
        callsChangedHandler?()
    }

    func remove(call: AddressableCall) {
        guard let index = calls.firstIndex(where: { $0 === call }) else { return }
        calls.remove(at: index)
        callsChangedHandler?()
    }

    func removeAllCalls() {
        calls.removeAll()
        callsChangedHandler?()
    }

    func end(call: AddressableCall) {
        let uuid = call.incomingCall?.uuid ?? call.outgoingCall?.uuid
        let endCallAction = CXEndCallAction(call: uuid!)
        let transaction = CXTransaction(action: endCallAction)

        requestTransaction(transaction)
    }


    func startCall(to: String) {
        let callHandle = CXHandle(type: .generic, value: to)
        let startCallAction = CXStartCallAction(call: UUID(), handle: callHandle)
        let transaction = CXTransaction(action: startCallAction)

        requestTransaction(transaction)
    }

    private func requestTransaction(_ transaction: CXTransaction) {
        callController.request(transaction) { error in
            if let error = error {
                print("Error requesting transaction: \(error)")
            } else {
                print("Requested transaction successfully")
            }
        }
    }

    func fetchToken(tokenReceived: @escaping (_ token: String?) -> Void ) {
        AddressableDataFetcher().getTwilioAccessToken()
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure:
                        tokenReceived(nil)
                    case .finished:
                        break
                    }
                },
                receiveValue: { tokenData in
                    tokenReceived(tokenData.jwt_token)
                })
            .store(in: &disposables)
    }
}

struct TwilioAccessToken: Codable {
    let success: Bool
    let jwt_token: String
}
