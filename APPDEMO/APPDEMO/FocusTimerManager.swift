
import SwiftUI
import Combine
import UserNotifications

@MainActor
final class FocusTimerManager: ObservableObject {

    static let shared = FocusTimerManager()

    @Published private(set) var remainingSeconds = 0
    @Published private(set) var isRunning = false
    @Published private(set) var needsExercise = false

    private var timer: Timer?
    private var endDate: Date?

    private let defaults = UserDefaults.standard
    private let endDateKey = "movoFocusTimerEndDate"
    private let exerciseKey = "movoNeedsExercise"

    private init() {
        restoreTimer()
    }
    
    // Ask permission to send notifications.
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in

            if let error = error {
                print("Notification permission error: \(error)")
            }

            print("Notifications allowed: \(granted)")
        }
    }
    
    // Schedule a notification when the focus timer ends.
    private func scheduleTimerNotification(seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Move!"
        content.body = "Your focus session is over. Complete an exercise to earn more time."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(seconds),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "MovoFocusTimer",
            content: content,
            trigger: trigger
        )

        let center = UNUserNotificationCenter.current()

        center.removePendingNotificationRequests(
            withIdentifiers: ["MovoFocusTimer"]
        )

        center.add(request) { error in
            if let error = error {
                print("Notification scheduling error: \(error)")
            }
        }
    }

    // Start a normal focus session in minutes.
    func start(minutes: Int) {
        guard minutes > 0 else { return }
        startTimer(seconds: minutes * 60)
    }

    // Start a short test session in seconds.
    func startTest(seconds: Int) {
        guard seconds > 0 else { return }
        startTimer(seconds: seconds)
    }

    // Shared timer-starting logic.
    private func startTimer(seconds: Int) {
        guard !needsExercise else { return }

        timer?.invalidate()

        let end = Date().addingTimeInterval(
            TimeInterval(seconds)
        )

        endDate = end
        defaults.set(end, forKey: endDateKey)

        isRunning = true
        updateRemainingTime()
        startTicking()
        requestNotificationPermission()
        scheduleTimerNotification(seconds: seconds)
    }

    // End the current session.
    func pause() {
        timer?.invalidate()
        timer = nil

        isRunning = false
        endDate = nil

        defaults.removeObject(forKey: endDateKey)
    }

    // Reset the entire timer state.
    func reset() {
        timer?.invalidate()
        timer = nil

        remainingSeconds = 0
        isRunning = false
        needsExercise = false
        endDate = nil

        defaults.removeObject(forKey: endDateKey)
        defaults.set(false, forKey: exerciseKey)
    }

    // Clear the exercise requirement.
    func exerciseCompleted(minutes: Int) {
        needsExercise = false
        defaults.set(false, forKey: exerciseKey)

        // Add the reward earned from the completed challenge.
        start(minutes: minutes)
    }
    // Update the countdown every second.
    private func startTicking() {
        timer?.invalidate()

        timer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateRemainingTime()
            }
        }
    }

    // Calculate remaining time using the actual end date.
    private func updateRemainingTime() {
        guard let endDate else { return }

        remainingSeconds = max(
            0,
            Int(ceil(endDate.timeIntervalSinceNow))
        )

        if remainingSeconds == 0 {
            timer?.invalidate()
            timer = nil

            isRunning = false
            needsExercise = true
            self.endDate = nil

            defaults.removeObject(forKey: endDateKey)
            defaults.set(true, forKey: exerciseKey)
        }
    }

    // Restore an active timer after reopening the app.
    private func restoreTimer() {
        needsExercise = defaults.bool(forKey: exerciseKey)

        guard let savedEndDate = defaults.object(
            forKey: endDateKey
        ) as? Date else {
            return
        }

        endDate = savedEndDate

        if savedEndDate <= Date() {
            remainingSeconds = 0
            needsExercise = true

            defaults.removeObject(forKey: endDateKey)
            defaults.set(true, forKey: exerciseKey)
        } else {
            isRunning = true
            updateRemainingTime()
            startTicking()
        }
    }

    // Format the countdown as MM:SS.
    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60

        return String(
            format: "%02d:%02d",
            minutes,
            seconds
        )
    }
}
