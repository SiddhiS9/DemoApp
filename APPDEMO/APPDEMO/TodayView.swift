import SwiftUI
import FamilyControls   // Label(token) for showing picked apps
import ManagedSettings  // the token types themselves

struct TodayView: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var screenTime: ScreenTimeManager
    let availableMinutes: Int
    let usedMinutes: Int
    let earnedMinutes: Int
    let onStartChallenge: () -> Void
    let onManageApps: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with movo branding
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("movo")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundStyle(Color.movoGreen)
                            Spacer()
                        }
                        
                        Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()).uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                            .tracking(0.8)
                        
                        Text("Your time, earned.")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color.movoDark)
                    }
                    .padding(.top, 8)

                    // Hero Circular Gauge Card
                    VStack(spacing: 16) {
                        Text("AVAILABLE SCREEN TIME")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)

                        ZStack {
                            Circle()
                                .stroke(Color.movoLightGreen, lineWidth: 14)
                                .frame(width: 170, height: 170)

                            Circle()
                                .trim(from: 0.0, to: state.remainingFraction)
                                .stroke(Color.movoGreen, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 170, height: 170)
                                .animation(.easeInOut(duration: 0.6), value: state.remainingFraction)

                            VStack(spacing: 2) {
                                Text("\(availableMinutes)")
                                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Color.movoDark)
                                Text("minutes left")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text("\(state.dailyAllowance) min daily allowance + \(earnedMinutes) min earned")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)

                        HStack {
                            Text("\(usedMinutes) min used")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.movoCoral)
                            Spacer()
                            Text("\(availableMinutes) min remaining")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.movoGreen)
                        }
                        .padding(.horizontal, 8)

                        Button(action: onStartChallenge) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Earn more time")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.movoDark)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.03), radius: 8, y: 3)

                    // Limited Apps Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Your limited apps")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color.movoDark)
                            Spacer()
                            Button("Manage", action: onManageApps)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.movoGreen)
                        }

                        VStack(spacing: 10) {
                            if limitedItems.isEmpty {
                                // Nothing picked yet: invite the user to choose apps.
                                Button(action: onManageApps) {
                                    AppRow(iconColor: .movoGreen, icon: "plus.app",
                                           title: "No apps limited yet",
                                           subtitle: "Tap to choose which apps Movo locks")
                                }
                                .buttonStyle(.plain)
                            } else {
                                ForEach(Array(limitedItems.prefix(maxRows).enumerated()), id: \.element) { index, item in
                                    if index > 0 { Divider() }
                                    LimitedItemRow(item: item, isLocked: availableMinutes == 0)
                                }
                                if limitedItems.count > maxRows {
                                    Divider()
                                    Button("+\(limitedItems.count - maxRows) more", action: onManageApps)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.movoGreen)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }

                    // Bottom Quick Move Promo
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("A quick move. A little more time.")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color.movoDark)
                            Text("Complete 20 squats to earn 10 extra minutes for your limited apps.")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                    .background(Color.movoLightGreen.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Color.movoBackground.ignoresSafeArea())
        }
    }
}

// MARK: - Limited apps (real Screen Time selection)

extension TodayView {
    /// Show at most this many rows on the home screen. The rest are behind "+N more".
    private var maxRows: Int { 4 }

    /// Everything the user picked in the Screen Time picker, flattened into one list.
    private var limitedItems: [LimitedItem] {
        let selection = screenTime.selection
        return selection.applicationTokens.map(LimitedItem.app)
            + selection.categoryTokens.map(LimitedItem.category)
            + selection.webDomainTokens.map(LimitedItem.site)
    }
}

/// One picked thing. The tokens are opaque: Movo can't read the app's name,
/// only hand the token back to iOS, which draws the real name and icon.
enum LimitedItem: Hashable {
    case app(ApplicationToken)
    case category(ActivityCategoryToken)
    case site(WebDomainToken)
}

struct LimitedItemRow: View {
    let item: LimitedItem
    let isLocked: Bool

    var body: some View {
        HStack(spacing: 14) {
            Group {
                // Label(token) is from FamilyControls: iOS fills in the name and icon privately.
                switch item {
                case .app(let token): Label(token)
                case .category(let token): Label(token)
                case .site(let token): Label(token)
                }
            }
            .labelStyle(.titleAndIcon)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.movoDark)
            .lineLimit(1)

            Spacer()

            Image(systemName: isLocked ? "lock.fill" : "lock.open")
                .font(.system(size: 13))
                .foregroundStyle(isLocked ? Color.movoCoral : Color.secondary)
        }
    }
}

struct AppRow: View {
    let iconColor: Color
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
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

            Image(systemName: "lock.fill")
                .font(.system(size: 13))
                .foregroundStyle(.secondary.opacity(0.7))
        }
    }
}
