import SwiftUI

@main
struct movoApp: App {
    init() {
           _ = NotificationManager.shared
       }

       var body: some Scene {
           WindowGroup {
               MainTabView()
           }
       }
}
