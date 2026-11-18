import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

// Code shared by the Movo app AND the MovoMonitor extension.
// In Xcode: select this file → File Inspector → Target Membership → tick MovoMonitor too.
//
// Everything here is `nonisolated` because the extension's callbacks are not on the main actor,
// while this project defaults every declaration to @MainActor.

// MARK: - Balance

/// The day's minute balance, stored in the App Group so the monitor extension can read it.
nonisolated struct MovoBalance: Codable, Equatable {
    var dailyAllowance: Int
    var earnedToday: Int
    /// Minutes used in *finished* monitoring sessions. The live session's usage is `SharedStore.sessionUsed`.
    var usedToday: Int
    /// Which day this balance belongs to.
    var day: Date

    var isFromToday: Bool { Calendar.current.isDateInToday(day) }

    /// Minutes left at the start of a session (the same formula AppState uses).
    var available: Int { max(0, dailyAllowance + earnedToday - usedToday) }

    /// Midnight reset: keep the allowance, drop yesterday's earned and used minutes.
    func rolledOver(to date: Date = .now) -> MovoBalance {
        MovoBalance(dailyAllowance: dailyAllowance, earnedToday: 0, usedToday: 0, day: date)
    }
}

// MARK: - App Group storage

nonisolated enum SharedStore {
    static let appGroupID = "group.com.affinux.movo"

    /// UserDefaults that the app and its extensions all read and write.
    /// Falls back to .standard only so a misconfigured App Group doesn't crash. If the group
    /// entitlement is missing, the monitor won't see the app's data.
    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    private enum Key {
        static let selection = "movo.selection"
        static let balance = "movo.balance"
        static let sessionGranted = "movo.session.granted"
        static let sessionUsed = "movo.session.used"
    }

    // FamilyActivitySelection is Codable. Its tokens are opaque, so we can't see which apps
    // they are, but we can save and restore them.
    static func loadSelection() -> FamilyActivitySelection {
        guard let data = defaults.data(forKey: Key.selection),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return FamilyActivitySelection() }
        return selection
    }

    static func saveSelection(_ selection: FamilyActivitySelection) {
        guard let data = try? JSONEncoder().encode(selection) else { return }
        defaults.set(data, forKey: Key.selection)
    }

    static func loadBalance() -> MovoBalance? {
        guard let data = defaults.data(forKey: Key.balance) else { return nil }
        return try? JSONDecoder().decode(MovoBalance.self, from: data)
    }

    static func saveBalance(_ balance: MovoBalance) {
        guard let data = try? JSONEncoder().encode(balance) else { return }
        defaults.set(data, forKey: Key.balance)
    }

    /// Minutes the current monitoring session allows (the available balance when it started).
    static var sessionGranted: Int {
        get { defaults.integer(forKey: Key.sessionGranted) }
        set { defaults.set(newValue, forKey: Key.sessionGranted) }
    }

    /// Minutes used so far in the current session. Written by the monitor extension.
    static var sessionUsed: Int {
        get { defaults.integer(forKey: Key.sessionUsed) }
        set { defaults.set(newValue, forKey: Key.sessionUsed) }
    }
}

extension FamilyActivitySelection {
    nonisolated var isEmpty: Bool {
        applicationTokens.isEmpty && categoryTokens.isEmpty && webDomainTokens.isEmpty
    }
}

// MARK: - Enforcement (shield + monitoring)

extension ManagedSettingsStore.Name {
    /// A named store, so the app and the extension edit the same set of restrictions.
    nonisolated static let movo = Self("movo")
}

nonisolated enum ScreenTimeEnforcer {
    static let activity = DeviceActivityName("movo.balance")
    private static let eventPrefix = "movo.used."

    /// Main entry point. Call it whenever the available balance changes.
    /// - 0 minutes left: shield the selected apps.
    /// - Minutes left: remove the shield and arm threshold events that re-shield once they're used.
    /// Monitoring keeps running in both cases, so the extension gets `intervalDidStart` at midnight.
    static func apply(availableMinutes: Int) {
        let selection = SharedStore.loadSelection()

        // Starting a new session resets the usage counter.
        SharedStore.sessionGranted = availableMinutes
        SharedStore.sessionUsed = 0

        guard !selection.isEmpty else {
            unshield()
            DeviceActivityCenter().stopMonitoring([activity])
            return
        }

        if availableMinutes > 0 {
            unshield()
        } else {
            shield(selection)
        }
        startMonitoring(minutes: availableMinutes, selection: selection)
    }

    static func shield(_ selection: FamilyActivitySelection) {
        let store = ManagedSettingsStore(named: .movo)
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        store.shield.webDomainCategories = selection.categoryTokens.isEmpty
            ? nil : .specific(selection.categoryTokens)
    }

    static func unshield() {
        ManagedSettingsStore(named: .movo).clearAllSettings()
    }

    /// Reads N back from an event named "movo.used.N".
    static func minutes(from event: DeviceActivityEvent.Name) -> Int? {
        guard event.rawValue.hasPrefix(eventPrefix) else { return nil }
        return Int(event.rawValue.dropFirst(eventPrefix.count))
    }

    private static func startMonitoring(minutes: Int, selection: FamilyActivitySelection) {
        // All-day interval that repeats daily. iOS calls intervalDidStart at each midnight.
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )

        // One event per step of usage, so the app can show real "used" minutes.
        // The last event is always exactly `minutes`. That one triggers the shield.
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for threshold in thresholds(upTo: minutes) {
            events[DeviceActivityEvent.Name("\(eventPrefix)\(threshold)")] = DeviceActivityEvent(
                applications: selection.applicationTokens,
                categories: selection.categoryTokens,
                webDomains: selection.webDomainTokens,
                threshold: DateComponents(hour: threshold / 60, minute: threshold % 60),
                // Count only usage from now on, not what was already used earlier today.
                includesPastActivity: false
            )
        }

        do {
            // Starting the same activity name again replaces the previous schedule and events.
            try DeviceActivityCenter().startMonitoring(activity, during: schedule, events: events)
        } catch {
            print("Movo: startMonitoring failed: \(error)")
        }
    }

    /// 1, 2, 3 … for small balances. Every 5 minutes above an hour, so we don't register hundreds of events.
    private static func thresholds(upTo minutes: Int) -> [Int] {
        guard minutes > 0 else { return [] }
        let step = minutes <= 60 ? 1 : 5
        var values = Array(stride(from: step, to: minutes, by: step))
        values.append(minutes)
        return values
    }
}
