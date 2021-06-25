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
import GoogleMaps
import GooglePlaces

// API Key Restrictions set on Google Cloud, safe to keep this key here for now
let googleMapsApiKey = "AIzaSyDKJ7-97nKoAeFrCeb1yPfoVDbrS8RttKM"

protocol PushKitEventDelegate: AnyObject {
    func credentialsUpdated(credentials: PKPushCredentials, deviceID: String)
    func credentialsInvalidated()
    func incomingPushReceived(payload: PKPushPayload)
    func incomingPushReceived(payload: PKPushPayload, completion: @escaping () -> Void)
}

// TODO: Name this back to 'AppDelegate' when Lint issue is solved - https://github.com/realm/SwiftLint/issues/2786
class Application: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate, ObservableObject {
    @Published var currentView: AddressableView = KeyChainServiceUtil.shared[userBasicAuthToken] != nil ?
        .dashboard(false) : .signIn
    @Published var selectedMailing: Mailing?
    @Published var callState: String = CallState.connecting.rawValue

    var callKitProvider: CallService?
    var callManager: CallManager?
    var latestPushCredentials: PKPushCredentials?

    lazy var dependencyProvider = DependencyProvider()
    lazy var voipRegistry = PKPushRegistry.init(queue: DispatchQueue.main)

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        GMSServices.provideAPIKey(googleMapsApiKey)
        GMSPlacesClient.provideAPIKey(googleMapsApiKey)

        callManager = CallManager(application: self)
        if let safeCallManager = callManager {
            callKitProvider = CallService(application: self, callManager: safeCallManager)
        }

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

        if let delegate = callKitProvider, let credentials = latestPushCredentials {
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

        if let delegate = callKitProvider {
            delegate.credentialsInvalidated()
        }
    }

    /**
     * This delegate method is available on iOS 11 and above. Call the completion handler once the
     * notification payload is passed to the `TwilioVoice.handleNotification()` method.
     */
    func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping () -> Void
    ) {
        print("pushRegistry:didReceiveIncomingPushWithPayload:forType:\(type) completion:")

        if let delegate = self.callKitProvider {
            delegate.incomingPushReceived(payload: payload, completion: completion)
        }

        DispatchQueue.main.async {
            completion()
        }
    }

    func verifyPermissions(completion: @escaping () -> Void) {
        /**
         * Microphone access is required for in-app phone calls. Push
         * notification permissions required ONLY if device token is not registered.
         */
        checkRecordPermission {[weak self] micPermissionGranted in
            guard micPermissionGranted else {
                DispatchQueue.main.async {
                    self?.displayPermissionsChangeAlert(
                        message: "Microphone permissions are required for in-app phone calls"
                    )
                }
                return
            }

            guard UserDefaults.standard.data(forKey: kCachedDeviceToken) == nil else {
                completion()
                return
            }

            checkPushNotificationsPermission {[weak self] pushNotificationPermissionGranted in
                guard pushNotificationPermissionGranted else {
                    DispatchQueue.main.async {
                        self?.displayPermissionsChangeAlert(
                            message: "Push notification permissions are required for in-app phone calls"
                        )
                    }
                    return
                }

                UNUserNotificationCenter.current().getNotificationSettings {[weak self] settings in
                    guard settings.authorizationStatus == .authorized else {
                        DispatchQueue.main.async {
                            self?.displayPermissionsChangeAlert(
                                message: "Push notification permissions are required for in-app phone calls"
                            )
                        }
                        return
                    }
                    completion()
                }
            }
        }
    }

    func displayPermissionsChangeAlert(message: String) {
        let alertController = UIAlertController(title: "Addressable", message: message, preferredStyle: .alert)

        let goToSettings = UIAlertAction(title: "Open Privacy Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url,
                                          options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly: false],
                                          completionHandler: nil)
            }
        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel)

        [goToSettings, cancel].forEach { alertController.addAction($0) }

        UIApplication.topViewController()?.present(alertController, animated: true, completion: nil)
    }
}

extension UIApplication {
    // TODO: Consider an alternative to using keyWindow here for displaying permissions alert on topViewController
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
    @UIApplicationDelegateAdaptor(Application.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            AppView().environmentObject(appDelegate)
        }.onChange(of: scenePhase) { phase in
            switch phase {
            case .background:
                print("App is in background")
            case .active:
                if KeyChainServiceUtil.shared[userBasicAuthToken] != nil {
                    appDelegate.verifyPermissions {
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }
                }
            case .inactive:
                print("App is Inactive")
            @unknown default:
                print("New App state not yet introduced")
            }
        }
    }
}
