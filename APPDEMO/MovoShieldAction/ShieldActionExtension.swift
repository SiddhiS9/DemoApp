import ManagedSettings
import UserNotifications

// MovoShieldAction: the Shield Action extension.
//
// Runs when a button on the shield is tapped. It replies with a response:
//   .close: dismiss the shielded app and go to the Home Screen
//   .defer: keep the shield up and redraw it (e.g. after changing state)
//   .none:  do nothing
//
// It can't open Movo directly (extensions have no openURL), so "Earn minutes" posts a local
// notification. Tapping it opens Movo. Notification permission is requested in ScreenTimeManager.
nonisolated class ShieldActionExtension: ShieldActionDelegate {

    override func handle(action: ShieldAction, for application: ApplicationToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler: completionHandler)
    }

    private func respond(to action: ShieldAction,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            let content = UNMutableNotificationContent()
            content.title = "Time to move 💪"
            content.body = "Tap to open Movo and earn more screen time."
            content.sound = .default
            let request = UNNotificationRequest(identifier: "movo.earn-minutes" /* matches AppDelegate */, content: content, trigger: nil)
            // Wait until the notification is queued before closing. The extension can be suspended right after.
            UNUserNotificationCenter.current().add(request) { _ in
                completionHandler(.close)
            }
        case .secondaryButtonPressed:
            completionHandler(.close)
        default:
            // Newer SDKs add shield submenu buttons. Movo doesn't configure any.
            completionHandler(.none)
        }
    }
}
