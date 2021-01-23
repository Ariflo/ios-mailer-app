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


    func startCall(to incomingLead: IncomingLead) {
        let callHandle = CXHandle(type: .generic, value: String(data: encode(incomingLead)!, encoding: .utf8) ?? "")
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

    func fetchToken(deviceID: String = "", tokenReceived: @escaping (_ token: String?) -> Void ) {
        AddressableDataFetcher().getTwilioAccessToken(
            encode(DeviceIDWrapper(deviceID: deviceID))
        )
        .sink(
            receiveCompletion: { value in
                switch value {
                case .failure(let error):
                    print("fetchToken() receiveCompletion error: \(error)")
                    tokenReceived(nil)
                case .finished:
                    break
                }
            },
            receiveValue: { tokenData in
                tokenReceived(tokenData.jwtToken)
            })
        .store(in: &disposables)
    }
}

struct TwilioAccessToken: Codable {
    let success: Bool
    let jwtToken: String

    enum CodingKeys: String, CodingKey {
        case success
        case jwtToken = "jwt_token"
    }
}
