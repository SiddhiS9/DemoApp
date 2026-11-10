import SwiftUI

struct ActivityView: View {
    let usedMinutes: Int
    let earnedMinutes: Int

    let weeklyStats: [(day: String, used: CGFloat, earned: CGFloat)] = [
        ("T", 35, 15),
        ("W", 20, 25),
        ("T", 28, 18),
        ("F", 22, 28),
        ("S", 40, 20),
        ("S", 30, 26),
        ("M", 15, 22)
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("A healthier balance.")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color.movoDark)
                        Text("Less scrolling. More moving. All you.")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Top Split Stat Cards
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("SCREEN TIME USED")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.secondary)
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("\(usedMinutes)")
                                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Color.movoCoral)
                                Text("min")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.movoCoral)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                        VStack(alignment: .leading, spacing: 6) {
                            Text("TIME EARNED")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.secondary)
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("+\(earnedMinutes)")
                                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Color.movoGreen)
                                Text("min")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.movoGreen)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }

                    // Screen Time This Week Bar Chart Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Screen time this week")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.movoDark)
                            Spacer()
                            Text("Daily")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.movoGreen)
                        }

                        HStack(spacing: 14) {
                            HStack(spacing: 4) {
                                Circle().fill(Color.movoCoral).frame(width: 6, height: 6)
                                Text("Used").font(.caption2).foregroundStyle(.secondary)
                            }
                            HStack(spacing: 4) {
                                Circle().fill(Color.movoGreen).frame(width: 6, height: 6)
                                Text("Earned").font(.caption2).foregroundStyle(.secondary)
                            }
                        }

                        // Bar pairs
                        HStack(alignment: .bottom, spacing: 14) {
                            ForEach(weeklyStats.indices, id: \.self) { i in
                                VStack(spacing: 6) {
                                    HStack(alignment: .bottom, spacing: 3) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.movoCoral)
                                            .frame(width: 10, height: weeklyStats[i].used * 1.5)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.movoGreen)
                                            .frame(width: 10, height: weeklyStats[i].earned * 1.5)
                                    }
                                    Text(weeklyStats[i].day)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 100)
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                    // Today's History
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Today's history")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color.movoDark)
                            Spacer()
                            Text(Date().formatted(.dateTime.month(.abbreviated).day()))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        }

                        VStack(spacing: 14) {
                            HistoryItem(
                                icon: "figure.walk",
                                iconColor: .movoGreen,
                                title: "Walking goal reached",
                                subtitle: "9:12 AM · 1,000 steps",
                                delta: "+15 min",
                                isPositive: true
                            )
                            Divider()
                            HistoryItem(
                                icon: "iphone",
                                iconColor: .movoCoral,
                                title: "Social apps",
                                subtitle: "8:40 AM · Screen time",
                                delta: "-25 min",
                                isPositive: false
                            )
                            Divider()
                            HistoryItem(
                                icon: "flame.fill",
                                iconColor: .movoGreen,
                                title: "Active movement",
                                subtitle: "8:15 AM · 10 minutes",
                                delta: "+20 min",
                                isPositive: true
                            )
                        }
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Color.movoBackground.ignoresSafeArea())
        }
    }
}

struct HistoryItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let delta: String
    let isPositive: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.movoDark)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(delta)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isPositive ? Color.movoGreen : Color.movoCoral)
        }
    }
}
