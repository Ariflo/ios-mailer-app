//
//  Call.swift
//  Addressable
//
//  Created by Ari on 1/9/21.
//

import Foundation
import TwilioVoice

enum CallState: String {
    case connecting = "Connecting..."
    case active = "Active"
    case held = "On Hold"
    case muted = "On Mute"
    case ended = ""
}

class AddressableCall {
    let outgoingCall: Call?
    let incomingCall: CallInvite?

    var state: CallState = .ended {
        didSet {
            stateChanged?()
        }
    }

    var stateChanged: (() -> Void)?
    var connectedStateChanged: (() -> Void)?

    init(incomingCall: CallInvite? = nil, outgoingCall: Call? = nil) {
        self.outgoingCall = outgoingCall
        self.incomingCall = incomingCall
    }

    func start(completion: ((_ success: Bool) -> Void)?) {
        completion?(true)

        DispatchQueue.main.async {
            self.state = .connecting

            DispatchQueue.main.async {
                self.state = .active
            }
        }
    }

    func answer() {
        state = .active
    }

    func muted() {
        state = .muted
    }

    func hold() {
        state = .held
    }

    func connecting() {
        state = .connecting
    }

    func end() {
        state = .ended
        outgoingCall?.disconnect()
        incomingCall?.reject()
    }
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
