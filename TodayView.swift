import SwiftUI

struct TodayView: View {
    @Binding var availableMinutes: Int
    let usedMinutes: Int
    let earnedMinutes: Int
    let onStartChallenge: () -> Void

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
                                .trim(from: 0.0, to: 0.75)
                                .stroke(Color.movoGreen, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 170, height: 170)

                            VStack(spacing: 2) {
                                Text("\(availableMinutes)")
                                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Color.movoDark)
                                Text("minutes left")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text("30 min daily allowance + \(earnedMinutes) min earned")
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
                            Button("Manage") {}
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.movoGreen)
                        }

                        VStack(spacing: 10) {
                            AppRow(iconColor: .movoCoral, icon: "iphone", title: "Social apps", subtitle: "Instagram · TikTok")
                            Divider().padding(.leading, 52)
                            AppRow(iconColor: .blue, icon: "play.tv.fill", title: "Entertainment", subtitle: "YouTube · Games")
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
