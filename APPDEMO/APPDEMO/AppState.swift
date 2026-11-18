import SwiftUI
import Combine

struct HistoryEntry: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
    let date: Date
    let deltaMinutes: Int   // positive = earned, negative = used

    var isPositive: Bool { deltaMinutes > 0 }
    var deltaText: String { "\(isPositive ? "+" : "-")\(abs(deltaMinutes)) min" }
    var subtitle: String { "\(date.formatted(date: .omitted, time: .shortened)) · \(detail)" }
}

/// Single source of truth for the minutes shown across every tab.
///
/// available = dailyAllowance + earnedToday - usedToday
///
/// How Screen Time ties in:
///  - The balance is saved to the App Group (`SharedStore`) so the MovoMonitor extension can see it.
///  - Every balance change starts a new "session": `ScreenTimeEnforcer.apply` unshields the apps and
///    arms threshold events for the available minutes, or shields them when nothing is left.
///  - While a session runs, the extension writes `SharedStore.sessionUsed`. `refresh()` pulls that
///    into `usedToday` when the app comes to the foreground.
final class AppState: ObservableObject {
    @Published var dailyAllowance: Int {
        didSet { if !isSyncing { startNewSession() } }
    }
    @Published private(set) var earnedToday: Int
    @Published private var usedInFinishedSessions: Int
    @Published private var usedInCurrentSession: Int
    @Published var history: [HistoryEntry]

    private var day: Date
    /// Set while we copy values from storage, so `dailyAllowance.didSet` doesn't start a session.
    private var isSyncing = false

    var usedToday: Int { usedInFinishedSessions + usedInCurrentSession }
    var availableMinutes: Int { max(0, dailyAllowance + earnedToday - usedToday) }
    var totalBudget: Int { dailyAllowance + earnedToday }
    var remainingFraction: Double {
        totalBudget > 0 ? min(1, Double(availableMinutes) / Double(totalBudget)) : 0
    }

    init() {
        if let stored = SharedStore.loadBalance() {
            dailyAllowance = stored.dailyAllowance
            earnedToday = stored.earnedToday
            usedInFinishedSessions = stored.usedToday
            usedInCurrentSession = 0   // refresh() picks up the live session's usage and logs it
            day = stored.day
            history = []
        } else {
            // First launch: start from the demo numbers.
            dailyAllowance = 30
            earnedToday = 35
            usedInFinishedSessions = 25
            usedInCurrentSession = 0
            day = .now
            history = AppState.seedHistory()
            SharedStore.saveBalance(balance)
        }
    }

    private var balance: MovoBalance {
        MovoBalance(dailyAllowance: dailyAllowance, earnedToday: earnedToday,
                    usedToday: usedInFinishedSessions, day: day)
    }

    // MARK: - Actions

    /// Called when a workout is completed. Adds the reward, records it, and unlocks the apps.
    func logWorkout(_ exercise: Exercise) {
        earnedToday += exercise.rewardMinutes
        history.insert(
            HistoryEntry(icon: exercise.icon,
                         title: exercise.displayName,
                         detail: "\(exercise.targetReps) reps",
                         date: Date(),
                         deltaMinutes: exercise.rewardMinutes),
            at: 0
        )
        startNewSession()
    }

    /// Call after the app selection or authorization changes, so the shield matches the new choice.
    func enforceScreenTime() {
        startNewSession()
    }

    /// Call when the app comes to the foreground. Pulls in what the monitor extension recorded
    /// and handles the midnight reset.
    func refresh() {
        if !Calendar.current.isDateInToday(day) {
            history.removeAll()
            if let stored = SharedStore.loadBalance(), stored.isFromToday {
                // The extension already did the midnight reset and started today's session. Use its values.
                adopt(stored)
            } else {
                isSyncing = true
                earnedToday = 0
                usedInFinishedSessions = 0
                usedInCurrentSession = 0
                day = .now
                isSyncing = false
                startNewSession(collectingUsage: false)
                return
            }
        }
        collectSessionUsage()
    }

    /// Demo helper (Profile tab) so you can re-run the demo from scratch.
    func resetDemo() {
        isSyncing = true
        dailyAllowance = 30
        isSyncing = false
        earnedToday = 35
        usedInFinishedSessions = 25
        usedInCurrentSession = 0
        day = .now
        history = AppState.seedHistory()
        startNewSession(collectingUsage: false)
    }

    #if DEBUG
    /// Demo/testing only: uses up the whole remaining balance so the limited apps lock right away.
    /// Wrapped in #if DEBUG, so it only exists in builds run from Xcode.
    func drainBalance() {
        collectSessionUsage()
        let remaining = availableMinutes
        if remaining > 0 {
            usedInFinishedSessions += remaining
            history.insert(
                HistoryEntry(icon: "iphone", title: "Demo: balance used up", detail: "Testing",
                             date: Date(), deltaMinutes: -remaining),
                at: 0
            )
        }
        startNewSession(collectingUsage: false)   // available is now 0, so this shields the apps
    }
    #endif

    // MARK: - Screen Time plumbing

    /// Closes the current session (keeping its usage), saves the balance, and starts a new one
    /// for whatever is now available.
    private func startNewSession(collectingUsage: Bool = true) {
        if collectingUsage { collectSessionUsage() }
        usedInFinishedSessions += usedInCurrentSession
        usedInCurrentSession = 0
        SharedStore.saveBalance(balance)
        ScreenTimeEnforcer.apply(availableMinutes: availableMinutes)
    }

    /// Reads the usage the monitor extension has counted in this session and logs the new part.
    private func collectSessionUsage() {
        let counted = SharedStore.sessionUsed
        let newMinutes = counted - usedInCurrentSession
        guard newMinutes > 0 else { return }
        usedInCurrentSession = counted
        history.insert(
            HistoryEntry(icon: "iphone", title: "Limited apps", detail: "Screen time",
                         date: Date(), deltaMinutes: -newMinutes),
            at: 0
        )
    }

    private func adopt(_ stored: MovoBalance) {
        isSyncing = true
        dailyAllowance = stored.dailyAllowance
        isSyncing = false
        earnedToday = stored.earnedToday
        usedInFinishedSessions = stored.usedToday
        usedInCurrentSession = 0
        day = stored.day
    }

    // MARK: - Sample data (matches the seeded totals: earned 35, used 25)
    private static func time(_ hour: Int, _ minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    private static func seedHistory() -> [HistoryEntry] {
        [
            HistoryEntry(icon: Exercise.pushUps.icon, title: "Push-ups", detail: "10 reps",
                         date: time(9, 12), deltaMinutes: 15),
            HistoryEntry(icon: "iphone", title: "Social apps", detail: "Screen time",
                         date: time(8, 40), deltaMinutes: -25),
            HistoryEntry(icon: Exercise.squats.icon, title: "Squats", detail: "20 reps",
                         date: time(8, 15), deltaMinutes: 10),
            HistoryEntry(icon: Exercise.abs.icon, title: "Abs", detail: "15 reps",
                         date: time(7, 50), deltaMinutes: 10)
        ]
    }
}
