import UIKit
import Combine
import UserNotifications

/// UIKit app delegate, hooked into SwiftUI with @UIApplicationDelegateAdaptor in movoApp.
///
/// Its only job: notice when the user taps the "earn minutes" notification posted by the
/// MovoShieldAction extension, so movoApp can open the workout sheet.
final class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    static let earnMinutesNotificationID = "movo.earn-minutes"   // must match ShieldActionExtension

    /// Set to true when the notification is tapped. movoApp resets it after opening the workout.
    @Published var openWorkoutRequested = false

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Set the delegate at launch, so a tap that cold-launches the app is still delivered.
        UNUserNotificationCenter.current().delegate = self
        // Ask for notification permission up front. The shield's "Earn minutes" button can only
        // reach Movo through a notification, so without this permission it silently does nothing.
        // iOS only shows the prompt once; after that this call just returns the saved answer.
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    /// Called when the user taps one of our notifications.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        if response.notification.request.identifier == Self.earnMinutesNotificationID {
            openWorkoutRequested = true
        }
    }
}
