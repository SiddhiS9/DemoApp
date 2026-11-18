//
//  EarnedTimeManager.swift
//  APPDEMO
//
//  Created by Samuel Devassy on 11/15/26.
//




import SwiftUI
import Combine

@MainActor
final class EarnedTimeManager: ObservableObject {

    static let shared = EarnedTimeManager()

    private let dailyAllowanceMinutes = 30

    @Published private(set) var remainingSeconds = 0
    @Published private(set) var earnedTodayMinutes = 0
    @Published private(set) var usedTodayMinutes = 0
    @Published private(set) var focusedTodaySeconds = 0

    private let defaults = UserDefaults.standard

    private let remainingKey = "movoRemainingSeconds"
    private let earnedKey = "movoEarnedToday"
    private let usedKey = "movoUsedToday"
    private let resetDateKey = "movoLastResetDate"
    private let focusedKey = "movoFocusedTodaySeconds"

    private init() {
        refresh()
    }

    // Reset the allowance when a new day begins.
    func refresh() {
        let today = Calendar.current.startOfDay(for: Date())

        if let savedDate = defaults.object(
            forKey: resetDateKey
        ) as? Date,
           Calendar.current.isDate(savedDate, inSameDayAs: today) {

            remainingSeconds = defaults.integer(
                forKey: remainingKey
            )

            earnedTodayMinutes = defaults.integer(
                forKey: earnedKey
            )

            usedTodayMinutes = defaults.integer(
                forKey: usedKey
            )
            
            focusedTodaySeconds = defaults.integer(
                forKey: focusedKey
            )

        } else {
            resetForNewDay(today: today)
        }
    }

    private func resetForNewDay(today: Date) {
        remainingSeconds = dailyAllowanceMinutes * 60
        earnedTodayMinutes = 0
        usedTodayMinutes = 0

        defaults.set(remainingSeconds, forKey: remainingKey)
        defaults.set(0, forKey: earnedKey)
        defaults.set(0, forKey: usedKey)
        defaults.set(today, forKey: resetDateKey)
    }

    // Add workout rewards to the remaining balance.
    func addTime(minutes: Int) {
        guard minutes > 0 else { return }

        refresh()

        remainingSeconds += minutes * 60
        earnedTodayMinutes += minutes

        saveBalance()
    }

    // Deduct time when Screen Time usage is recorded.
    func consume(seconds: Int) {
        guard seconds > 0 else { return }

        refresh()

        let amountToConsume = min(seconds, remainingSeconds)

        remainingSeconds -= amountToConsume
        usedTodayMinutes += amountToConsume / 60

        saveBalance()
    }
    
    // Record actual time spent focusing.
    func addFocusedTime(seconds: Int) {
        guard seconds > 0 else { return }

        refresh()

        focusedTodaySeconds += seconds

        saveBalance()
    }

    // Convert focused seconds into whole minutes for ActivityView.
    var focusedTodayMinutes: Int {
        focusedTodaySeconds / 60
    }

    private func saveBalance() {
        defaults.set(remainingSeconds, forKey: remainingKey)
        defaults.set(earnedTodayMinutes, forKey: earnedKey)
        defaults.set(usedTodayMinutes, forKey: usedKey)
        defaults.set(focusedTodaySeconds, forKey: focusedKey)
    }

    var remainingMinutes: Int {
        Int(ceil(Double(remainingSeconds) / 60))
    }

    var isUnlocked: Bool {
        remainingSeconds > 0
    }

    var formattedTime: String {
        let hours = remainingSeconds / 3600
        let minutes = (remainingSeconds % 3600) / 60
        let seconds = remainingSeconds % 60

        if hours > 0 {
            return String(
                format: "%02d:%02d:%02d",
                hours, minutes, seconds
            )
        }

        return String(
            format: "%02d:%02d",
            minutes, seconds
        )
    }
}

struct EarnedTimeStatusView: View {

    @StateObject private var manager =
        EarnedTimeManager.shared

    private let timer = Timer.publish(
        every: 60,
        on: .main,
        in: .common
    ).autoconnect()

    var body: some View {
        VStack(spacing: 16) {

            Image(
                systemName: manager.isUnlocked
                ? "lock.open.fill"
                : "lock.fill"
            )
            .font(.system(size: 40))
            .foregroundStyle(Color.movoGreen)

            Text(
                manager.isUnlocked
                ? "Scroll Time Available"
                : "No Scroll Time Available"
            )
            .font(.title2.bold())

            Text(manager.formattedTime)
                .font(
                    .system(
                        size: 48,
                        weight: .heavy,
                        design: .rounded
                    )
                )
                .monospacedDigit()

            Text("Available balance")

                .foregroundStyle(.secondary)

            Text(
                "\(manager.earnedTodayMinutes) minutes earned today"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(
                "30-minute daily allowance + workout rewards"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(
                "Usage deductions will connect to Screen Time later."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .onReceive(timer) { _ in
            manager.refresh()
        }
        .onAppear {
            manager.refresh()
        }
    }
}
