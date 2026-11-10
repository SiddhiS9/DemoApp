import SwiftUI

struct EarnTimeView: View {
    let balanceMinutes: Int
    let earnedToday: Int
    let onSelectChallenge: (String, Int, Int) -> Void

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Move. Earn. Enjoy.")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color.movoDark)
                        Text("Complete a challenge to add screen time.")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Current Balance Pill
                    HStack {
                        Image(systemName: "stopwatch.fill")
                            .foregroundStyle(Color.movoGreen)
                        Text("Your balance: **\(balanceMinutes) min**")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.movoDark)
                        Spacer()
                        Text("+\(earnedToday) today")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.movoGreen)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(Capsule())

                    // Featured Quick Challenge Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("QUICK CHALLENGE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.movoGreen)
                            Spacer()
                            Text("+10 MIN")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundStyle(Color.movoGreen)
                        }

                        // Category Icon Pills
                        HStack(spacing: 12) {
                            BadgeIcon(systemName: "figure.strengthtraining.traditional", active: true)
                            BadgeIcon(systemName: "bolt.fill", active: false)
                            BadgeIcon(systemName: "timer", active: false)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("20 squats. 10 more minutes.")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color.movoDark)
                            Text("A little effort, a well-earned break.")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }

                        Button {
                            onSelectChallenge("Squats", 20, 10)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                Text("Start challenge")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.movoDark)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(20)
                    .background(Color.movoLightGreen.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    // Next Reward List
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Choose your next reward")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.movoDark)

                        RewardTile(
                            icon: "figure.walk",
                            iconColor: .orange,
                            title: "Take a walk",
                            subtitle: "1,000 steps · Walking",
                            reward: "+15 min",
                            action: { onSelectChallenge("Walking", 1000, 15) }
                        )

                        RewardTile(
                            icon: "figure.jumprope",
                            iconColor: .blue,
                            title: "Push-up break",
                            subtitle: "10 reps · Strength",
                            reward: "+5 min",
                            action: { onSelectChallenge("Push-ups", 10, 5) }
                        )
                    }

                    Text("Rewards are added after activity is verified on camera.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Color.movoBackground.ignoresSafeArea())
        }
    }
}

struct BadgeIcon: View {
    let systemName: String
    let active: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(active ? Color.movoGreen.opacity(0.18) : Color.white)
                .frame(width: 44, height: 44)
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(active ? Color.movoGreen : .secondary)
        }
    }
}

struct RewardTile: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let reward: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18))
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

                Text(reward)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.movoGreen)
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
