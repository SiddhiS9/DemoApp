import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var state: AppState
    let onManageApps: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your settings.")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color.movoDark)
                        Text("Set your own balance.")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Daily allowance
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DAILY ALLOWANCE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)

                        HStack {
                            Text("\(state.dailyAllowance) min")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color.movoDark)
                                .contentTransition(.numericText())
                            Spacer()
                            Stepper("", value: $state.dailyAllowance, in: 10...120, step: 5)
                                .labelsHidden()
                        }
                        Text("Free minutes you get each day before you need to earn more.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.movoCard)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    // Settings rows
                    VStack(spacing: 14) {
                        Button(action: onManageApps) {
                            SettingsRow(icon: "lock.fill", tint: .movoCoral,
                                        title: "Limited apps", subtitle: "Choose what gets locked", showsChevron: true)
                        }
                        .buttonStyle(.plain)
                        Divider()
                        Button(action: onManageApps) {
                            SettingsRow(icon: "checkmark.shield.fill", tint: .movoGreen,
                                        title: "Always allowed", subtitle: "Phone, Messages, Maps", showsChevron: true)
                        }
                        .buttonStyle(.plain)
                        Divider()
                        SettingsRow(icon: "figure.cross.training", tint: .blue,
                                    title: "Exercises", subtitle: Exercise.allCases.map(\.displayName).joined(separator: " · "),
                                    showsChevron: false)
                    }
                    .padding(16)
                    .background(Color.movoCard)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    Button {
                        withAnimation { state.resetDemo() }
                    } label: {
                        Text("Reset demo data")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.movoCoral)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.movoLightCoral)
                            .clipShape(Capsule())
                    }

                    #if DEBUG
                    Button {
                        withAnimation { state.drainBalance() }
                    } label: {
                        Text("Demo: set remaining to 0 min")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.movoDark)
                            .clipShape(Capsule())
                    }
                    #endif
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Color.movoBackground.ignoresSafeArea())
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    let showsChevron: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.movoDark)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary.opacity(0.7))
            }
        }
        .contentShape(Rectangle())
    }
}
