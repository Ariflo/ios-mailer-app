//
//  PermissionsUtil.swift
//  Addressable
//
//  Created by Ari on 1/13/21.
//
import TwilioVoice
import UserNotifications

func checkRecordPermission(completion: @escaping (_ permissionGranted: Bool) -> Void) {
    let permissionStatus = AVAudioSession.sharedInstance().recordPermission

    switch permissionStatus {
    case .granted:
        // Record permission already granted.
        completion(true)
    case .denied:
        // Record permission denied.
        completion(false)
    case .undetermined:
        // Requesting record permission.
        // Optional: pop up app dialog to let the users know if they want to request.
        AVAudioSession.sharedInstance().requestRecordPermission { granted in completion(granted) }
    default:
        completion(false)
    }
}

func checkPushNotificationsPermission(completion: @escaping (_ permissionGranted: Bool) -> Void) {
    UNUserNotificationCenter.current()
        .requestAuthorization(options: [.alert, .sound, .badge, .carPlay]) { permissionGranted, _ in
            completion(permissionGranted)
        }
}
