import SwiftUI
import FamilyControls

/// Connect Screen Time, then choose which apps Movo locks when the balance hits zero.
struct ManageAppsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var screenTime: ScreenTimeManager

    @State private var isPickerPresented = false
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.movoGreen)

            Text(screenTime.isAuthorized ? "Choose your apps" : "Connect Screen Time")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.movoDark)

            Text(screenTime.isAuthorized
                 ? "These apps lock when your minutes run out. Everything else stays available."
                 : "Movo uses Screen Time to lock the apps you pick until you earn more minutes.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if screenTime.isAuthorized {
                selectionCard
            }

            if let error = screenTime.errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.movoCoral)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                if screenTime.isAuthorized {
                    isPickerPresented = true
                } else {
                    Task {
                        isRequesting = true
                        await screenTime.requestAuthorization()
                        isRequesting = false
                        if screenTime.isAuthorized { isPickerPresented = true }
                    }
                }
            } label: {
                Group {
                    if isRequesting {
                        ProgressView().tint(.white)
                    } else {
                        Text(screenTime.isAuthorized ? "Choose apps" : "Enable Screen Time")
                    }
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.movoGreen)
                .clipShape(Capsule())
            }
            .disabled(isRequesting)
            .padding(.horizontal, 32)
            .padding(.top, 4)

            Button("Done") { dismiss() }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.movoDark)
                .padding(.top, 2)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.movoBackground.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        // Apple's picker. It runs out of process, so Movo only gets opaque tokens and never sees app names.
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $screenTime.selection)
        .onChange(of: screenTime.selection) {
            // New selection → re-apply the shield/monitoring to the new set of apps.
            state.enforceScreenTime()
        }
    }

    private var selectionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("LIMITED")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(state.availableMinutes > 0 ? "\(state.availableMinutes) min left" : "Locked now")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(state.availableMinutes > 0 ? Color.movoGreen : Color.movoCoral)
            }

            Text(screenTime.selectionSummary)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.movoDark)

            // Label(token) shows the real app icon and name. The system renders them, not Movo.
            if !screenTime.selection.applicationTokens.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(screenTime.selection.applicationTokens), id: \.self) { token in
                            Label(token)
                                .labelStyle(.iconOnly)
                                .scaleEffect(1.4)
                                .frame(width: 36, height: 36)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.movoCard)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 24)
    }
}
