//
//  Call.swift
//  Addressable
//
//  Created by Ari on 1/9/21.
//

import Foundation
import TwilioVoice

enum CallState {
    case connecting
    case active
    case held
    case ended
}

enum ConnectedState {
    case pending
    case complete
}

class AddressableCall {
    let outgoingCall: Call?
    let incomingCall: CallInvite?

    var state: CallState = .ended {
        didSet {
            stateChanged?()
        }
    }

    var connectedState: ConnectedState = .pending {
        didSet {
            connectedStateChanged?()
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.state = .connecting
            self.connectedState = .pending

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.state = .active
                self.connectedState = .complete
            }
        }
    }

    func answer() {
        state = .active
    }

    func end() {
        state = .ended
        outgoingCall?.disconnect()
        incomingCall?.reject()
    }
}
