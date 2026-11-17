import Foundation
import DeviceActivity
import ManagedSettings
import FamilyControls

class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    let store = ManagedSettingsStore()

    private let sharedDefaults = UserDefaults(
        suiteName: "group.samueldevassy.APPDEMO"
    )

    override func intervalDidStart(
        for activity: DeviceActivityName
    ) {
        super.intervalDidStart(for: activity)

        // Start each new daily interval without an old shield.
        if activity == DeviceActivityName("movoDailyActivity") {
            store.shield.applications = nil
        }
    }

    override func intervalDidEnd(
        for activity: DeviceActivityName
    ) {
        super.intervalDidEnd(for: activity)

        // Don't remove the shield here.
        // The next daily interval will reset it.
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)

        guard activity == DeviceActivityName("movoDailyActivity") else {
            return
        }

        guard event == DeviceActivityEvent.Name("movoUsageLimit") else {
            return
        }

        // Retrieve the app selection shared by the main Movo app.
        guard
            let data = sharedDefaults?.data(
                forKey: "movoFamilyActivitySelection"
            ),
            let selection = try? JSONDecoder().decode(
                FamilyActivitySelection.self,
                from: data
            )
        else {
            return
        }

        // Shield the selected applications.
        store.shield.applications = selection.applicationTokens
    }
}
