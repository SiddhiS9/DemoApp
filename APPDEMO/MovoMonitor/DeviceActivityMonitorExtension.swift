import DeviceActivity
import ManagedSettings

// MovoMonitor: the Device Activity Monitor extension.
//
// iOS launches this briefly in the background when a scheduled interval starts or ends, or when
// usage of the selected apps crosses one of the thresholds the app registered. It can't show UI.
// It reads and writes the App Group and edits the shield.
//
// Needs MovoShared.swift in this target (Target Membership) for SharedStore / ScreenTimeEnforcer.
//
// `nonisolated` because these callbacks don't run on the main actor.
nonisolated class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    /// Fires at midnight (the daily schedule restarts), and also right after the app calls startMonitoring.
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        guard activity == ScreenTimeEnforcer.activity,
              let balance = SharedStore.loadBalance(),
              !balance.isFromToday
        else { return }   // Same day: the app just (re)started monitoring, so nothing to do.

        // New day: reset earned/used, then unlock with the fresh daily allowance.
        // Movo may not be opened today, so this has to happen here.
        let today = balance.rolledOver()
        SharedStore.saveBalance(today)
        ScreenTimeEnforcer.apply(availableMinutes: today.available)
    }

    /// Fires each time total usage of the selected apps crosses a threshold ("movo.used.N").
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        guard activity == ScreenTimeEnforcer.activity,
              let minutesUsed = ScreenTimeEnforcer.minutes(from: event)
        else { return }

        // Record usage so the app can show it in "used today" next time it opens.
        SharedStore.sessionUsed = max(SharedStore.sessionUsed, minutesUsed)

        // The final threshold equals the minutes this session allowed: time's up, lock the apps.
        if minutesUsed >= SharedStore.sessionGranted {
            ScreenTimeEnforcer.shield(SharedStore.loadSelection())
        }
    }
}
