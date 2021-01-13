//
//  AddressableApp.swift
//  Addressable
//
//  Created by Arian Flores on 12/1/20.
//

import SwiftUI
import PushKit
import UIKit

protocol PushKitEventDelegate: AnyObject {
    func credentialsUpdated(credentials: PKPushCredentials)
    func credentialsInvalidated()
    func incomingPushReceived(payload: PKPushPayload)
    func incomingPushReceived(payload: PKPushPayload, completion: @escaping () -> Void)
}

class AppDelegate: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate {
    var pushKitEventDelegate: PushKitEventDelegate?
    lazy var voipRegistry = PKPushRegistry.init(queue: DispatchQueue.main)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        pushKitEventDelegate = ProviderDelegate(callManager: CallManager())

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

    /**
     * This delegate method is available on iOS 11 and above. Call the completion handler once the
     * notification payload is passed to the `TwilioVoice.handleNotification()` method.
     */
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        checkRecordPermission { micPermissionGranted in
            guard !micPermissionGranted else {
                print("pushRegistry:didReceiveIncomingPushWithPayload:forType:completion:")

                if let delegate = self.pushKitEventDelegate {
                    delegate.incomingPushReceived(payload: payload, completion: completion)
                }

                if let version = Float(UIDevice.current.systemVersion), version >= 13.0 {
                    /**
                     * The Voice SDK processes the call notification and returns the call invite synchronously. Report the incoming call to
                     * CallKit and fulfill the completion before exiting this callback method.
                     */
                    completion()
                }
                return
            }

            let alertController = UIAlertController(title: "Addressable",
                                                    message: "Microphone permission required for phone call",
                                                    preferredStyle: .alert)

            let goToSettings = UIAlertAction(title: "Open Privacy Settings", style: .default) { _ in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                          options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly: false],
                                          completionHandler: nil)
            }

            let cancel = UIAlertAction(title: "cancel", style: .cancel)

            [goToSettings, cancel].forEach { alertController.addAction($0) }

            UIApplication.topViewController()?.present(alertController, animated: true, completion: nil)
        }
    }
}

extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}

@main
struct AddressableApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase

    @State var showPermissionsAlert = false

    var body: some Scene {
        WindowGroup {
            NavigationView {
                AppView()
            }
        }.onChange(of: scenePhase) { phase in
            switch phase {
            case .background:
                print("App is in background")
            case .active:
                print("App is Active")
            case .inactive:
                print("App is Inactive")
            @unknown default:
                print("New App state not yet introduced")
            }
        }
    }
}
