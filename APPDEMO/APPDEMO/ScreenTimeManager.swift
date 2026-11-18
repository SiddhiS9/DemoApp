import Foundation
import Combine
import FamilyControls
import UserNotifications

/// Owns Screen Time authorization and the user's chosen apps.
/// The minutes logic lives in AppState. This class only covers "is Movo allowed to block?" and "block what?".
final class ScreenTimeManager: ObservableObject {

    @Published private(set) var authorizationStatus: AuthorizationStatus

    /// What the user picked in FamilyActivityPicker. Saved to the App Group on every change
    /// so the monitor extension can shield the same apps.
    @Published var selection: FamilyActivitySelection {
        didSet { SharedStore.saveSelection(selection) }
    }

    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    init() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        selection = SharedStore.loadSelection()

        // The user can revoke access in Settings → Screen Time, so watch for changes.
        AuthorizationCenter.shared.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in self?.authorizationStatus = status }
            .store(in: &cancellables)
    }

    var isAuthorized: Bool { authorizationStatus == .approved }

    var selectionSummary: String {
        let apps = selection.applicationTokens.count
        let categories = selection.categoryTokens.count
        let sites = selection.webDomainTokens.count
        var parts: [String] = []
        if apps > 0 { parts.append("\(apps) app\(apps == 1 ? "" : "s")") }
        if categories > 0 { parts.append("\(categories) categor\(categories == 1 ? "y" : "ies")") }
        if sites > 0 { parts.append("\(sites) site\(sites == 1 ? "" : "s")") }
        return parts.isEmpty ? "Nothing selected yet" : parts.joined(separator: " · ")
    }

    /// Shows the system Screen Time prompt. `.individual` means the user is limiting their own
    /// device, not a child's through Family Sharing.
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorizationStatus = AuthorizationCenter.shared.authorizationStatus
            errorMessage = nil
            // The shield's "Earn minutes" button posts a notification, so ask for that permission here too.
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            authorizationStatus = AuthorizationCenter.shared.authorizationStatus
            errorMessage = "Screen Time access wasn't granted: \(error.localizedDescription)"
        }
    }
}
