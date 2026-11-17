//
//  NotificationManager.swift
//  APPDEMO
//
//  Created by Samuel Devassy on 11/16/26.
//



import SwiftUI
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // Show notifications even when Movo is open.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    // Tapping the "Time to Move!" notification opens the exercise screen.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.identifier == "MovoFocusTimer" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: Notification.Name("StartMovoExercise"),
                    object: nil
                )
            }
        }
        completionHandler()
    }
}
