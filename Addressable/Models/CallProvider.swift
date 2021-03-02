//
//  CallProvider.swift
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
let twimlParamFrom = "From"
let twimlParamTo = "To"
let addressableParamSessionID = "SessionId"

class CallProvider: NSObject {
    private var app: Application
    private var callManager: CallManager
    private let provider: CXProvider

    /*
     Custom ringback will be played when this flag is enabled.
     When [answerOnBridge](https://www.twilio.com/docs/voice/twiml/dial#answeronbridge) is enabled in
     the <Dial> TwiML verb, the caller will not hear the ringback while the call is ringing and awaiting
     to be accepted on the callee's side. Configure this flag based on the TwiML application.
     */
    var playCustomRingback = false
    var ringtonePlayer: AVAudioPlayer?

    var audioDevice = DefaultAudioDevice()
    var callKitCompletionCallback: ((Bool) -> Void)?

    var incomingPushCompletionCallback: (() -> Void)?
    var userInitiatedDisconnect: Bool = false

    init(application: Application, callManager: CallManager) {
        self.app = application
        self.callManager = callManager

        provider = CXProvider(configuration: CallProvider.providerConfiguration)

        super.init()
        provider.setDelegate(self, queue: nil)
        /*
         * The important thing to remember when providing a TVOAudioDevice is that the device must be set
         * before performing any other actions with the SDK (such as connecting a Call, or accepting an incoming Call).
         * In this case we've already initialized our own `TVODefaultAudioDevice` instance which we will now set.
         */
        TwilioVoiceSDK.audioDevice = audioDevice
    }

    static var providerConfiguration: CXProviderConfiguration = {
        let providerConfiguration = CXProviderConfiguration()

        providerConfiguration.supportsVideo = true
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.phoneNumber]

        return providerConfiguration
    }()
}

// MARK: - CXCallProvider
extension CallProvider: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        print("Stopping audio")
        audioDevice.isEnabled = false

        for call in callManager.calls {
            call.end()
        }

        callManager.removeAllCalls()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("provider:performAnswerCallAction:")

        performAnswerVoiceCall(uuid: action.callUUID) {[weak self] success in
            if success {
                print("performAnswerVoiceCall() successful")
                // Display Incoming Call View while In-App
                self?.app.displayCallView = true
            } else {
                print("performAnswerVoiceCall() failed")
                action.fail()
            }
        }

        configureAudioSession()

        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        print("provider:performSetHeldAction:")

        if let call = callManager.currentActiveCall {
            call.isOnHold = action.isOnHold
            app.callStatusText = action.isOnHold ? CallState.held.rawValue : CallState.active.rawValue
            action.fulfill()
        } else {
            action.fail()
        }
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        print("provider:performSetMutedAction:")

        if let call = callManager.currentActiveCall {
            call.isMuted = action.isMuted
            app.callStatusText = action.isMuted ? CallState.muted.rawValue : CallState.active.rawValue
            action.fulfill()
        } else {
            action.fail()
        }
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("Starting audio")
        audioDevice.isEnabled = true
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("provider:didDeactivateAudioSession:")
        audioDevice.isEnabled = false
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("provider:performEndCallAction:")
        guard let addressableCall = callManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        print("Stopping audio")
        if app.displayCallView {
            DispatchQueue.main.async {
                self.app.displayCallView = false
            }
        }

        if let invite = addressableCall.incomingCall {
            invite.reject()
            callManager.remove(call: addressableCall)
        } else if let call = addressableCall.outgoingCall {
            call.disconnect()
        } else {
            print("Unknown UUID to perform end-call action with")
        }
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("provider:performStartCallAction:")

        configureAudioSession()

        provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: Date())
        let lead = try? JSONDecoder().decode(IncomingLead.self, from: action.handle.value.data(using: .utf8)!)

        performVoiceCall(uuid: action.callUUID, lead: lead!) { success in
            if success {
                print("performVoiceCall() successful")
                provider.reportOutgoingCall(with: action.callUUID, connectedAt: Date())
            } else {
                print("performVoiceCall() failed")
            }
        }

        action.fulfill()
        playCustomRingback = true
    }

    func reportIncomingCall(
        callInvite: CallInvite,
        from: String,
        hasVideo: Bool = false,
        completion: ((Error?) -> Void)?
    ) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: from)
        update.hasVideo = hasVideo

        provider.reportNewIncomingCall(with: callInvite.uuid, update: update) { error in
            if error == nil {
                let call = AddressableCall(incomingCall: callInvite)
                self.callManager.add(call)
            }
            completion?(error)
        }
    }

    func performAnswerVoiceCall(uuid: UUID, completionHandler: @escaping (Bool) -> Void) {
        guard let incomingAddressableCall = callManager.callWithUUID(uuid: uuid) else {
            print("No CallInvite matches the UUID")
            return
        }
        let callInvite = incomingAddressableCall.incomingCall!

        let acceptOptions = AcceptOptions(callInvite: callInvite) { builder in
            builder.uuid = callInvite.uuid
        }
        let call = callInvite.accept(options: acceptOptions, delegate: self)

        callManager.currentActiveCall = call
        callManager.add(AddressableCall(incomingCall: nil, outgoingCall: call))

        callKitCompletionCallback = completionHandler
        callManager.remove(call: incomingAddressableCall)

        guard #available(iOS 13, *) else {
            incomingPushHandled()
            return
        }
    }

    func performVoiceCall(uuid: UUID, lead: IncomingLead, completionHandler: @escaping (Bool) -> Void) {
        callManager.fetchToken {[weak self] tokenData in
            guard let accessToken = tokenData?.jwtToken, let to = lead.fromNumber, let from = lead.toNumber else { return }
            guard let userClientIdentity = tokenData?.twilioClientIdentity else { return }

            self?.callManager.currentActiveCallFrom = from

            let connectOptions = ConnectOptions(accessToken: accessToken) { builder in
                builder.params = [twimlParamFrom: from, twimlParamTo: to, addressableParamSessionID: userClientIdentity]
                builder.uuid = uuid
            }

            let call = TwilioVoiceSDK.connect(options: connectOptions, delegate: self!)
            self?.callManager.currentActiveCall = call
            self?.callManager.add(AddressableCall(incomingCall: nil, outgoingCall: call))
            self?.callKitCompletionCallback = completionHandler
        }
    }
}

// MARK: - TVOCallDelegate

extension CallProvider: CallDelegate {
    func callDidStartRinging(call: Call) {
        print("callDidStartRinging:")

        /*
         When [answerOnBridge](https://www.twilio.com/docs/voice/twiml/dial#answeronbridge) is enabled in the
         <Dial> TwiML verb, the caller will not hear the ringback while the call is ringing and awaiting to be
         accepted on the callee's side. The application can use the `AVAudioPlayer` to play custom audio files
         between the `[TVOCallDelegate callDidStartRinging:]` and the `[TVOCallDelegate callDidConnect:]` callbacks.
         */
        if playCustomRingback {
            playRingback()
        }
        app.callStatusText = CallState.connecting.rawValue
    }

    // MARK: Ringtone
    func playRingback() {
        let ringtonePath = URL(fileURLWithPath: Bundle.main.path(forResource: "ringtone", ofType: "wav")!)

        do {
            ringtonePlayer = try AVAudioPlayer(contentsOf: ringtonePath)
            ringtonePlayer?.delegate = self
            ringtonePlayer?.numberOfLoops = -1

            ringtonePlayer?.volume = 1.0
            ringtonePlayer?.play()
        } catch {
            print("Failed to initialize audio player")
        }
    }

    func stopRingback() {
        guard let ringtonePlayer = ringtonePlayer, ringtonePlayer.isPlaying else { return }

        ringtonePlayer.stop()
    }

    func callDidConnect(call: Call) {
        print("callDidConnect:")

        if playCustomRingback {
            stopRingback()
        }

        if let callKitCompletionCallback = callKitCompletionCallback {
            callKitCompletionCallback(true)
        }

        app.callStatusText = CallState.active.rawValue
    }

    func callDidFailToConnect(call: Call, error: Error) {
        print("Call failed to connect: \(error.localizedDescription)")

        if let completion = callKitCompletionCallback {
            completion(false)
        }

        if playCustomRingback {
            stopRingback()
        }

        if app.displayCallView {
            DispatchQueue.main.async {
                self.app.displayCallView = false
            }
        }

        provider.reportCall(with: call.uuid!, endedAt: Date(), reason: CXCallEndedReason.failed)

        callDisconnected(call: call)
    }

    func callDidDisconnect(call: Call, error: Error?) {
        if let error = error {
            print("Call failed: \(error.localizedDescription)")
        } else {
            print("Call disconnected")
        }

        if playCustomRingback {
            stopRingback()
        }

        if app.displayCallView {
            DispatchQueue.main.async {
                self.app.displayCallView = false
            }
        }

        if !userInitiatedDisconnect {
            var reason = CXCallEndedReason.remoteEnded

            if error != nil {
                reason = .failed
            }
            provider.reportCall(with: call.uuid!, endedAt: Date(), reason: reason)
        }

        callDisconnected(call: call)
    }

    func callDisconnected(call: Call) {
        if call == callManager.currentActiveCall {
            callManager.currentActiveCall = nil
        }

        guard let addressableCall = callManager.callWithUUID(uuid: call.uuid!) else {
            print("No call matches the UUID")
            return
        }

        callManager.remove(call: addressableCall)

        userInitiatedDisconnect = false

        if playCustomRingback {
            stopRingback()
        }

        if app.displayCallView {
            DispatchQueue.main.async {
                self.app.displayCallView = false
            }
        }
    }
}

// MARK: - PushKitEventDelegate

extension CallProvider: PushKitEventDelegate {
    func credentialsUpdated(credentials: PKPushCredentials, deviceID: String) {
        if registrationRequired() || UserDefaults.standard.data(forKey: kCachedDeviceToken) != credentials.token {
            callManager.fetchToken(deviceID: deviceID) { tokenData in
                guard let accessToken = tokenData?.jwtToken else { return }
                guard let userClientIdentity = tokenData?.twilioClientIdentity else { return }

                KeyChainServiceUtil.shared[userMobileClientIdentity] = userClientIdentity
                let cachedDeviceToken = credentials.token
                /*
                 * Perform registration if a new device token is detected.
                 */
                TwilioVoiceSDK.register(accessToken: accessToken, deviceToken: cachedDeviceToken) { error in
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
            let lastBindingCreated = UserDefaults.standard.object(forKey: kCachedBindingDate) as? Date
        else { return true }

        let date = Date()
        var components = DateComponents()
        components.setValue(kRegistrationTTLInDays / 2, for: .day)
        let expirationDate = Calendar.current.date(byAdding: components, to: lastBindingCreated)

        if expirationDate?.compare(date) == ComparisonResult.orderedDescending {
            return false
        }
        return true
    }

    func credentialsInvalidated() {
        callManager.fetchToken { tokenData in
            guard let accessToken = tokenData?.jwtToken, let deviceToken = UserDefaults.standard.data(forKey: kCachedDeviceToken) else { return }

            TwilioVoiceSDK.unregister(accessToken: accessToken, deviceToken: deviceToken) { error in
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
        TwilioVoiceSDK.handleNotification(payload.dictionaryPayload, delegate: self, delegateQueue: nil)
    }

    func incomingPushReceived(payload: PKPushPayload, completion: @escaping () -> Void) {
        // The Voice SDK will use main queue to invoke `cancelledCallInviteReceived:error:` when delegate queue is not passed
        TwilioVoiceSDK.handleNotification(payload.dictionaryPayload, delegate: self, delegateQueue: nil)
    }

    func incomingPushHandled() {
        guard let completion = incomingPushCompletionCallback else { return }

        incomingPushCompletionCallback = nil
        completion()
    }
}

// MARK: - TVONotificaitonDelegate

extension CallProvider: NotificationDelegate {
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

        // Report incoming call to iOS
        let from = (callInvite.from ?? "").replacingOccurrences(of: "client:", with: "")

        let backgroundTaskIdentifier =
            UIApplication.shared.beginBackgroundTask(expirationHandler: nil)

        self.reportIncomingCall(
            callInvite: callInvite,
            from: from
        ) { _ in
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
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

// MARK: - AVAudioPlayerDelegate

extension CallProvider: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            print("Audio player finished playing successfully")
        } else {
            print("Audio player finished playing with some error")
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("Decode error occurred: \(error.localizedDescription)")
        }
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
