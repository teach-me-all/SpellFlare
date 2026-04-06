//
//  NotificationService.swift
//  spelling-bee iOS App
//
//  Handles push notification permission, FCM token registration,
//  foreground display, and tap-to-navigate deep linking.
//

import Foundation
import UIKit
import UserNotifications
import FirebaseMessaging
import FirebaseFunctions

// MARK: - Notification.Name extension

extension Notification.Name {
    /// Posted when a push notification tap should navigate the app.
    /// userInfo may contain "competitionId": String.
    static let navigateFromPushNotification = Notification.Name("navigateFromPushNotification")
}

// MARK: - NotificationService

final class NotificationService: NSObject {
    static let shared = NotificationService()

    private let functions = Functions.functions()

    private override init() { super.init() }

    // MARK: - Permission + Registration

    /// Request notification permission and set up FCM token handling.
    /// Safe to call on every launch — iOS only shows the dialog once.
    func requestPermissionAndRegister() async {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return }

        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }

        // MessagingDelegate fires didReceiveRegistrationToken once the APNs token is bound.
        Messaging.messaging().delegate = self
    }

    // MARK: - Tap handling

    /// Parse a notification response and broadcast navigation intent.
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        NotificationCenter.default.post(
            name: .navigateFromPushNotification,
            object: nil,
            userInfo: userInfo
        )
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Show banner + play sound even when the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// Handle tap on a notification while the app is background/closed.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotificationResponse(response)
        completionHandler()
    }
}

// MARK: - MessagingDelegate

extension NotificationService: MessagingDelegate {
    /// Called whenever the FCM token is assigned or rotated. Register it to Firestore.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        functions.httpsCallable("registerFCMToken").call(["token": token]) { _, error in
            if let error {
                print("NotificationService: failed to register FCM token: \(error)")
            }
        }
    }
}
