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

enum CallState: String {
    case connecting = "Connecting..."
    case active = "Active"
    case held = "On Hold"
    case muted = "On Mute"
    case ended = "Call Ended"
}

enum CallerName: String {
    case defaultName = "Addressable Mailing Caller"
}

class CallManager {
    private var app: Application
    private let callController = CXCallController()
    var disposables = Set<AnyCancellable>()

    var incomingLeads: [IncomingLead] = []
    var accountSmartNumberForCurrentCall: String = ""

    var incomingCalls: [String: Call] = [:]
    var activeCallInvites: [String: CallInvite] = [:]
    var activeCalls: [String: Call] = [:]

    var currentActiveCall: Call?
    var currentCallerID = CallerID()
    var calledIncomingLead: IncomingLead?

    init(application: Application) {
        self.app = application
    }


    func getLeadFromLatestCall() -> IncomingLead? {
        guard let call = currentActiveCall else {
            print("No currentActiveCall to getLeadFromLatestCall() in CallManager")
            return nil
        }

        guard let uuid = call.uuid else {
            print("No UUID to getLeadFromLatestCall() in CallManager")
            return nil
        }

        guard let relatedIncomingCall = incomingCalls[uuid.uuidString] else {
            // Lead Related to Outgoing Call
            if calledIncomingLead != nil {
                // swiftlint:disable force_unwrapping
                return incomingLeads.first { lead in lead.id == calledIncomingLead!.id }
            }
            print("No relatedIncomingCall to getLeadFromLatestCall() in CallManager")
            return nil
        }

        guard let fromNumber = relatedIncomingCall.from else {
            print("No fromNumber to getLeadFromLatestCall() in CallManager")
            return nil
        }

        return incomingLeads.first { lead in
            lead.fromNumber == fromNumber.replacingOccurrences(of: "+", with: "")
        }
    }

    func addActiveCall(_ call: Call, tagAsIncoming: Bool = false) {
        guard let uuid = call.uuid else {
            print("No UUID to addActiveCall in CallManager")
            return
        }

        currentActiveCall = call
        activeCalls[uuid.uuidString] = call

        if tagAsIncoming {
            incomingCalls[uuid.uuidString] = call
        }
    }

    func addCallInvite(_ callInvite: CallInvite) {
        activeCallInvites[callInvite.uuid.uuidString] = callInvite
    }

    func removeCall(with uuid: UUID) {
        let removedCall = activeCallInvites.removeValue(forKey: uuid.uuidString) ??
            activeCalls.removeValue(forKey: uuid.uuidString)

        if removedCall == nil {
            print("Something went terribly wrong in CallManager.removeCall for uuid: \(uuid.uuidString)")
        }
    }

    func removeAllCalls() {
        for callInvite in activeCallInvites.values {
            removeCall(with: callInvite.uuid)
        }

        for call in activeCalls.values {
            guard let uuid = call.uuid else { continue }
            removeCall(with: uuid)
        }

        if !incomingCalls.isEmpty {
            incomingCalls.removeAll()
        }
    }

    func endCall(with uuid: UUID) {
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)

        requestTransaction(transaction)
    }

    func startCall(to incomingLead: IncomingLead) {
        guard let incomingLeadData = encode(incomingLead),
              let leadDataString = String(data: incomingLeadData, encoding: .utf8) else {
            print("No incomingLeadData in startCall() for CallManager to make call")
            return
        }
        let callHandle = CXHandle(type: .generic, value: leadDataString)
        let startCallAction = CXStartCallAction(call: UUID(), handle: callHandle)
        let transaction = CXTransaction(action: startCallAction)

        requestTransaction(transaction)
        calledIncomingLead = incomingLead
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
        ApiService(provider: app.dependencyProvider).getTwilioAccessToken(
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
        ApiService(provider: app.dependencyProvider).getIncomingLeads()
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

    func resetActiveCallState(for uuid: UUID? = nil) {
        guard let callUuid = uuid else {
            print("No UUID to remove call in resetActiveCallState()")
            return
        }

        currentCallerID = CallerID()
        currentActiveCall = nil
        calledIncomingLead = nil
        removeCall(with: callUuid)

        if !incomingCalls.isEmpty {
            incomingCalls.removeAll()
        }
    }

    func getIsCurrentCallIncoming() -> Bool {
        guard let activeCall = currentActiveCall else {
            print("No currentActiveCall to getIsCurrentCallIncoming()")
            return false
        }
        guard let uuid = activeCall.uuid else {
            print("No uuid to getIsCurrentCallIncoming()")
            return false
        }
        return incomingCalls[uuid.uuidString] != nil
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
    var caller: String = CallerName.defaultName.rawValue
    var relatedMailingName: String = ""
}

// MARK: - CallParticipantResponse
struct CallParticipantResponse: Codable {
    let status: String

    enum CodingKeys: String, CodingKey {
        case status
    }
}

// MARK: - NewCaller
struct NewCaller: Codable {
    let sessionID: String
    let addNumber: String
    let fromNumber: String

    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case addNumber = "add_number"
        case fromNumber = "from_number"
    }
}
