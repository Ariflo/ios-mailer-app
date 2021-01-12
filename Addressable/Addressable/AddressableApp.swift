//
//  AddressableApp.swift
//  Addressable
//
//  Created by Arian Flores on 12/1/20.
//

import SwiftUI
import PushKit

protocol PushKitEventDelegate: AnyObject {
    func credentialsUpdated(credentials: PKPushCredentials)
    func credentialsInvalidated()
    func incomingPushReceived(payload: PKPushPayload)
    func incomingPushReceived(payload: PKPushPayload, completion: @escaping () -> Void)
}

class AppDelegate: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate {
    weak var pushKitEventDelegate: PushKitEventDelegate?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        pushKitEventDelegate = (ProviderDelegate(callManager: CallManager()) as! PushKitEventDelegate)
        let voipRegistry = PKPushRegistry.init(queue: DispatchQueue.main)

        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = Set([PKPushType.voIP])

        return true
    }

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        print("pushRegistry:didUpdatePushCredentials:forType:")

        if let delegate = pushKitEventDelegate {
            delegate.credentialsUpdated(credentials: pushCredentials)
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("pushRegistry:didInvalidatePushTokenForType:")

        if let delegate = self.pushKitEventDelegate {
            delegate.credentialsInvalidated()
        }
    }
}

@main
struct AddressableApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            NavigationView {
                AppView()
            }
        }
    }
}
