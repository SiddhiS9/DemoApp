import ManagedSettings
import ManagedSettingsUI
import UIKit

// MovoShieldConfig: the Shield Configuration extension.
//
// When a shielded app is opened, iOS asks this extension how the block screen should look.
// You only return a ShieldConfiguration (colors, icon, text, button labels). iOS renders it.
// Button taps go to the MovoShieldAction extension.
nonisolated class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    // Movo brand colors (same values as Theme.swift; extensions can't see the app's code).
    private let movoGreen = UIColor(red: 0 / 255, green: 178 / 255, blue: 110 / 255, alpha: 1)
    private let movoDark = UIColor(red: 29 / 255, green: 38 / 255, blue: 49 / 255, alpha: 1)

    private func movoShield(for name: String?) -> ShieldConfiguration {
        let subtitle = name.map { "You're out of screen time for \($0). Do a quick workout in Movo to earn more minutes." }
            ?? "You're out of screen time. Do a quick workout in Movo to earn more minutes."

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: movoDark,
            icon: UIImage(systemName: "figure.run.circle.fill")?
                .withTintColor(movoGreen, renderingMode: .alwaysOriginal),
            title: ShieldConfiguration.Label(text: "App Locked", color: .white),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: UIColor.white.withAlphaComponent(0.75)),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Earn minutes in Movo", color: .white),
            primaryButtonBackgroundColor: movoGreen,
            secondaryButtonLabel: ShieldConfiguration.Label(text: "Close", color: movoGreen)
        )
    }

    // Shielded because the app itself was selected.
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        movoShield(for: application.localizedDisplayName)
    }

    // Shielded because its category was selected (e.g. "Social").
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        movoShield(for: application.localizedDisplayName)
    }

    // Shielded websites in Safari.
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        movoShield(for: webDomain.domain)
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        movoShield(for: webDomain.domain)
    }
}
