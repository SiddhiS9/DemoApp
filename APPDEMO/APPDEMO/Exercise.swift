import SwiftUI

/// The exercises movo supports. These match the 3 classes in WorkoutDetect_1.mlmodel
/// (Abs, Push-Ups, Squats). To add an exercise, the model must be retrained with it first.
enum Exercise: String, CaseIterable, Identifiable {
    case squats, pushUps, abs

    var id: String { rawValue }

    /// Exact class label the Core ML model outputs. Samuel: match against this.
    var modelLabel: String {
        switch self {
        case .squats:  return "Squats"
        case .pushUps: return "Push-Ups"
        case .abs:     return "Abs"
        }
    }

    var displayName: String {
        switch self {
        case .squats:  return "Squats"
        case .pushUps: return "Push-ups"
        case .abs:     return "Abs"
        }
    }

    var category: String {
        switch self {
        case .squats:  return "Legs"
        case .pushUps: return "Upper body"
        case .abs:     return "Core"
        }
    }

    var icon: String {
        switch self {
        case .squats:  return "figure.strengthtraining.functional"
        case .pushUps: return "figure.strengthtraining.traditional"
        case .abs:     return "figure.core.training"
        }
    }

    /// Reps needed to earn the reward. Easy to tune.
    var targetReps: Int {
        switch self {
        case .squats:  return 20
        case .pushUps: return 10
        case .abs:     return 15
        }
    }

    /// Minutes of screen time earned for finishing the target reps. Easy to tune.
    var rewardMinutes: Int {
        switch self {
        case .squats:  return 10
        case .pushUps: return 15
        case .abs:     return 10
        }
    }

    var headline: String {
        "\(targetReps) \(displayName.lowercased()). \(rewardMinutes) more minutes."
    }

    var subtitle: String { "\(targetReps) reps · \(category)" }
}
