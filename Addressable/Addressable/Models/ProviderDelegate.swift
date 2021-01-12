//
//  ProviderDelegate.swift
//  Addressable
//
//  Created by Ari on 1/7/21.
//

import AVFoundation
import CallKit
import TwilioVoice
import PushKit
import SwiftUI

let kRegistrationTTLInDays = 365

let kCachedDeviceToken = "CachedDeviceToken"
let kCachedBindingDate = "CachedBindingDate"

class ProviderDelegate: NSObject {
    private var callManager: CallManager
    private let provider: CXProvider

    var incomingPushCompletionCallback: (() -> Void)?

    init(callManager: CallManager) {
        self.callManager = callManager

        provider = CXProvider(configuration: ProviderDelegate.providerConfiguration)

        super.init()
        provider.setDelegate(self, queue: nil)
    }

    static var providerConfiguration: CXProviderConfiguration = {
        let providerConfiguration = CXProviderConfiguration()

        providerConfiguration.supportsVideo = true
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.phoneNumber]

        return providerConfiguration
    }()

    func reportIncomingCall(
        callInvite: CallInvite,
        from: String,
        hasVideo: Bool = false,
        completion: ((Error?) -> Void)?
    ) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .phoneNumber, value: from)
        update.hasVideo = hasVideo

        provider.reportNewIncomingCall(with: callInvite.uuid, update: update) { error in
            if error == nil {
                let call = AddressableCall(incomingCall: callInvite)
                self.callManager.add(call)
            }
            completion?(error)
        }
    }
}

// MARK: - CXProviderDelegate
extension ProviderDelegate: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        print("Stopping audio")

        for call in callManager.calls {
            call.end()
        }

        callManager.removeAllCalls()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        configureAudioSession()
        call.answer()
        action.fulfill()
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("Starting audio")
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        print("Stopping audio")
        call.end()
        action.fulfill()
        callManager.remove(call: call)
    }
}

// MARK: - PushKitEventDelegate

extension ProviderDelegate: PushKitEventDelegate {
    func credentialsUpdated(credentials: PKPushCredentials) {
        if registrationRequired() || UserDefaults.standard.data(forKey: kCachedDeviceToken) != credentials.token {
            callManager.fetchToken { token in
                guard let accessToken = token else { return }

                let cachedDeviceToken = credentials.token
                /*
                 * Perform registration if a new device token is detected.
                 */
                TwilioVoice.register(accessToken: accessToken, deviceToken: cachedDeviceToken) { error in
                    if let error = error {
                        print("An error occurred while registering: \(error.localizedDescription)")
                    } else {
                        print("Successfully registered for VoIP push notifications.")

                        // Save the device token after successfully registered.
                        UserDefaults.standard.set(cachedDeviceToken, forKey: kCachedDeviceToken)

                        /**
                         * The TTL of a registration is 1 year. The TTL for registration for this device/identity
                         * pair is reset to 1 year whenever a new registration occurs or a push notification is
                         * sent to this device/identity pair.
                         */
                        UserDefaults.standard.set(Date(), forKey: kCachedBindingDate)
                    }
                }
            }
        } else {
            return
        }
    }

    /**
     * The TTL of a registration is 1 year. The TTL for registration for this device/identity pair is reset to
     * 1 year whenever a new registration occurs or a push notification is sent to this device/identity pair.
     * This method checks if binding exists in UserDefaults, and if half of TTL has been passed then the method
     * will return true, else false.
     */
    func registrationRequired() -> Bool {
        guard
            let lastBindingCreated = UserDefaults.standard.object(forKey: kCachedBindingDate)
        else { return true }

        let date = Date()
        var components = DateComponents()
        components.setValue(kRegistrationTTLInDays / 2, for: .day)
        let expirationDate = Calendar.current.date(byAdding: components, to: lastBindingCreated as! Date)!

        if expirationDate.compare(date) == ComparisonResult.orderedDescending {
            return false
        }
        return true
    }

    func credentialsInvalidated() {
        callManager.fetchToken { token in
            guard let accessToken = token, let deviceToken = UserDefaults.standard.data(forKey: kCachedDeviceToken) else { return }


            TwilioVoice.unregister(accessToken: accessToken, deviceToken: deviceToken) { error in
                if let error = error {
                    print("An error occurred while unregistering: \(error.localizedDescription)")
                } else {
                    print("Successfully unregistered from VoIP push notifications.")
                }
            }

            UserDefaults.standard.removeObject(forKey: kCachedDeviceToken)

            // Remove the cached binding as credentials are invalidated
            UserDefaults.standard.removeObject(forKey: kCachedBindingDate)
        }
    }

    func incomingPushReceived(payload: PKPushPayload) {
        // The Voice SDK will use main queue to invoke `cancelledCallInviteReceived:error:` when delegate queue is not passed
        TwilioVoice.handleNotification(payload.dictionaryPayload, delegate: self, delegateQueue: nil)
    }

    func incomingPushReceived(payload: PKPushPayload, completion: @escaping () -> Void) {
        // The Voice SDK will use main queue to invoke `cancelledCallInviteReceived:error:` when delegate queue is not passed
        TwilioVoice.handleNotification(payload.dictionaryPayload, delegate: self, delegateQueue: nil)
    }

    func incomingPushHandled() {
        guard let completion = incomingPushCompletionCallback else { return }

        incomingPushCompletionCallback = nil
        completion()
    }
}

// MARK: - TVONotificaitonDelegate

extension ProviderDelegate: NotificationDelegate {
    func callInviteReceived(callInvite: CallInvite) {
        print("callInviteReceived:")

        /**
         * The TTL of a registration is 1 year. The TTL for registration for this device/identity
         * pair is reset to 1 year whenever a new registration occurs or a push notification is
         * sent to this device/identity pair.
         */
        UserDefaults.standard.set(Date(), forKey: kCachedBindingDate)

        let callerInfo: TVOCallerInfo = callInvite.callerInfo
        if let verified: NSNumber = callerInfo.verified {
            if verified.boolValue {
                print("Call invite received from verified caller number!")
            }
        }

        // Report incoming call to OS
        let from = (callInvite.from ?? "").replacingOccurrences(of: "client:", with: "")

        let backgroundTaskIdentifier =
            UIApplication.shared.beginBackgroundTask(expirationHandler: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.reportIncomingCall(
                callInvite: callInvite,
                from: from
            ) { _ in
                UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            }
        }
    }

    func cancelledCallInviteReceived(cancelledCallInvite: CancelledCallInvite, error: Error) {
        print("cancelledCallInviteCanceled:error:, error: \(error.localizedDescription)")

        if callManager.calls.isEmpty {
            print("No pending call invite")
            return
        }

        guard let index = callManager.calls.firstIndex(where: { $0.incomingCall?.callSid == cancelledCallInvite.callSid }) else { return }

        callManager.end(call: callManager.calls[index])
    }
}


func configureAudioSession() {
    print("Configuring audio session")
    let session = AVAudioSession.sharedInstance()
    do {
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [])
    } catch let error {
        print("Error while configuring audio session: \(error)")
    }
}
