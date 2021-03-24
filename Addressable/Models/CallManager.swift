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
    var incomingLeads: [IncomingLead] = []
    var accountSmartNumberForCurrentCall: String = ""

    private let callController = CXCallController()

    private(set) var calls: [AddressableCall] = []
    var currentActiveCall: Call?
    var previousActiveCall: Call?
    var currentCallerID: CallerID = CallerID()

    func getLeadFromLastCall() -> IncomingLead? {
        return self.incomingLeads.first(
            where: {
                if let currCall = currentActiveCall {
                    return $0.fromNumber == currCall.from?.replacingOccurrences(of: "+", with: "")
                } else {
                    return $0.fromNumber == previousActiveCall?.from?.replacingOccurrences(of: "+", with: "")
                }
            })
    }

    func callWithUUID(uuid: UUID) -> AddressableCall? {
        guard let index = calls.firstIndex(where: { $0.incomingCall?.uuid == uuid || $0.outgoingCall?.uuid == uuid }) else {
            return nil
        }
        return calls[index]
    }

    func getCurrentAddressableCall() -> AddressableCall? {
        guard let currentActiveCall = currentActiveCall else {
            print("No currentActiveCall avaliable to end")
            return nil
        }

        guard let index = calls.firstIndex(where: { $0.incomingCall?.uuid == currentActiveCall.uuid || $0.outgoingCall?.uuid == currentActiveCall.uuid }) else { return nil }

        return calls[index]
    }

    func getIsCallIncoming() -> Bool {
        guard let currentActiveCall = currentActiveCall else {
            print("No currentActiveCall avaliable to end")
            return false
        }

        guard let index = calls.firstIndex(where: { $0.incomingCall?.uuid == currentActiveCall.uuid || $0.outgoingCall?.uuid == currentActiveCall.uuid }) else { return false }

        return ((calls[index].outgoingCall?.to?.contains("client")) != nil)
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
        guard let callId = uuid else {
            print("No Call UUID to end call")
            return
        }
        let endCallAction = CXEndCallAction(call: callId)
        let transaction = CXTransaction(action: endCallAction)

        requestTransaction(transaction)
    }

    func startCall(to incomingLead: IncomingLead) {
        let callHandle = CXHandle(type: .generic, value: String(data: encode(incomingLead)!, encoding: .utf8) ?? "")
        let startCallAction = CXStartCallAction(call: UUID(), handle: callHandle)
        let transaction = CXTransaction(action: startCallAction)

        requestTransaction(transaction)
    }

    func setHeld(call: Call, onHold: Bool) {
        guard let callUUID = call.uuid else {
            print("No UUID Avaliable to Hold Call")
            return
        }
        let setHeldCallAction = CXSetHeldCallAction(call: callUUID, onHold: onHold)

        let transaction = CXTransaction()
        transaction.addAction(setHeldCallAction)

        requestTransaction(transaction)
    }

    func setMuted(call: Call, isMuted: Bool) {
        guard let callUUID = call.uuid else {
            print("No UUID Avaliable to Hold Call")
            return
        }
        let setHeldCallAction = CXSetMutedCallAction(call: callUUID, muted: isMuted)

        let transaction = CXTransaction()
        transaction.addAction(setHeldCallAction)

        requestTransaction(transaction)
    }

    func toggleAudioToSpeaker(isSpeakerOn: Bool) {
        let session = AVAudioSession.sharedInstance()
        do {
            let audioOption = isSpeakerOn ? AVAudioSession.PortOverride.speaker : AVAudioSession.PortOverride.none
            try session.overrideOutputAudioPort(audioOption)
        } catch let error {
            print("Error while configuring speaker audio session: \(error)")
        }
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

    func fetchToken(deviceID: String = "", tokenReceived: @escaping (_ tokenData: TwilioAccessTokenData?) -> Void ) {
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
                tokenReceived(tokenData)
            })
        .store(in: &disposables)
    }

    func getLatestIncomingLeadsList() {
        AddressableDataFetcher().getIncomingLeads()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { value in
                    switch value {
                    case .failure(let error):
                        print("getLatestIncomingLeadsList() receiveCompletion error: \(error)")
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] incomingLeads in
                    guard let self = self else { return }
                    self.incomingLeads = incomingLeads
                })
            .store(in: &disposables)
    }

}

struct TwilioAccessTokenData: Codable {
    let success: Bool
    let jwtToken: String
    let twilioClientIdentity: String

    enum CodingKeys: String, CodingKey {
        case success
        case jwtToken = "jwt_token"
        case twilioClientIdentity = "twilio_client_identity"
    }
}

struct CallerID {
    var caller: String = "Addressable Mailing Caller"
    var relatedMailingName: String = ""
}
