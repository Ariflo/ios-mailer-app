//
//  AddressableApp.swift
//  Addressable
//
//  Created by Arian Flores on 12/1/20.
//

import SwiftUI
import PushKit
import Combine
import UserNotifications

protocol PushKitEventDelegate: AnyObject {
    func credentialsUpdated(credentials: PKPushCredentials, deviceID: String)
    func credentialsInvalidated()
    func incomingPushReceived(payload: PKPushPayload)
    func incomingPushReceived(payload: PKPushPayload, completion: @escaping () -> Void)
}

class AppDelegate: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate, ObservableObject {
    @Published var displayCallView: Bool = false
    @Published var callStatusText: String = ""

    var callkitProviderDelegate: ProviderDelegate?
    var callManager: CallManager?
    var latestPushCredentials: PKPushCredentials?
    lazy var voipRegistry = PKPushRegistry.init(queue: DispatchQueue.main)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        callManager = CallManager()
        callkitProviderDelegate = ProviderDelegate(application: self, callManager: callManager!)

        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = Set([PKPushType.voIP])

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()

        if let delegate = callkitProviderDelegate, let credentials = latestPushCredentials {
            delegate.credentialsUpdated(credentials: credentials, deviceID: token)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register APN: \(error)")
    }

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        print("pushRegistry:didUpdatePushCredentials:forType: \(type)")
        latestPushCredentials = pushCredentials
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("pushRegistry:didInvalidatePushTokenForType: \(type)")

        if let delegate = callkitProviderDelegate {
            delegate.credentialsInvalidated()
        }
    }

    /**
     * This delegate method is available on iOS 11 and above. Call the completion handler once the
     * notification payload is passed to the `TwilioVoice.handleNotification()` method.
     */
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print("pushRegistry:didReceiveIncomingPushWithPayload:forType:\(type) completion:")

        if let delegate = self.callkitProviderDelegate {
            delegate.incomingPushReceived(payload: payload, completion: completion)
        }

        DispatchQueue.main.async {
            completion()
        }
    }

    func verifyPermissions(completion: @escaping () -> Void) {
        /**
         * Both microphone and push notification access are required for in app phone calls on Addressable.
         */
        checkPushNotificationsPermission {[weak self] pushNotificationPermissionGranted in
            guard pushNotificationPermissionGranted else {
                DispatchQueue.main.async {
                    self?.displayPermissionsChangeAlert(message: "Push notification permissions are required to recieve in-app phone calls")
                }
                return
            }

            UNUserNotificationCenter.current().getNotificationSettings {[weak self] settings in
                guard settings.authorizationStatus == .authorized else {
                    DispatchQueue.main.async {
                        self?.displayPermissionsChangeAlert(message: "Push notification permissions are required to recieve in-app phone calls")
                    }
                    return
                }

                checkRecordPermission {[weak self] micPermissionGranted in
                    guard micPermissionGranted else {
                        DispatchQueue.main.async {
                            self?.displayPermissionsChangeAlert(message: "Microphone permissions are required for in-app phone calls")
                        }
                        return
                    }
                    completion()
                }
            }
        }
    }

    func displayPermissionsChangeAlert(message: String) {
        let alertController = UIAlertController(title: "Addressable",
                                                message: message,
                                                preferredStyle: .alert)

        let goToSettings = UIAlertAction(title: "Open Privacy Settings", style: .default) { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                      options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly: false],
                                      completionHandler: nil)
        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel)

        [goToSettings, cancel].forEach { alertController.addAction($0) }

        UIApplication.topViewController()?.present(alertController, animated: true, completion: nil)
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

    var body: some Scene {
        WindowGroup {
            NavigationView {
                AppView().environmentObject(appDelegate)
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
